#!/usr/bin/env bash
# Local nightly build for this machine: build only when HEAD moved since the
# last successful run.
#
#   tool/build_nightly.sh           # build if HEAD changed, else skip
#   tool/build_nightly.sh --force   # build unconditionally
#
# Output: build/nightly/droidEdit-<version>-<short-hash>[-dirty].apk
#
# Machine-specific workarounds (each one cost a failed build):
#   * dl.google.com is unreachable: mirrors are declared in
#     android/settings.gradle.kts, android/build.gradle.kts, the Flutter SDK's
#     build-logic settings, and ~/.local/share/gradle/init.d/.
#   * Guix exports C_INCLUDE_PATH/CPLUS_INCLUDE_PATH; the NDK clang then
#     resolves <stdint.h> against the host glibc and dies on gnu/stubs-32.h.
#   * flutter_soloud's native-asset hook needs kernel headers; its child clang
#     gets a filtered env, so the flags are injected through a PATH wrapper.
#   * android/key.properties names a keystore that is not on this machine;
#     Gradle fails instead of falling back to the debug key, so the file is
#     parked for the duration of the build.
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER=${FLUTTER:-/home/brokenshine/Programs/flutter-sdk/bin/flutter}
OUT_DIR=build/nightly
STAMP=$OUT_DIR/last-built.txt
head=$(git rev-parse HEAD)
hash=$(git rev-parse --short HEAD)
if git status --porcelain | grep -q .; then hash="$hash-dirty"; fi

if [ "${1:-}" != "--force" ] && [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$head" ]; then
  echo "no changes since $(git log -1 --format='%h %s' "$head"); skipping"
  exit 0
fi

# Gradle needs a full JDK; the Guix profile ships openjdk's JRE output, which
# has no javac (toolchain fails with JAVA_COMPILER missing).
GRADLE_PROPS="${GRADLE_USER_HOME:-$HOME/.local/share/gradle}/gradle.properties"
jdk=$(sed -n 's/^org.gradle.java.home=//p' "$GRADLE_PROPS" 2>/dev/null || true)
if [ -z "$jdk" ] || [ ! -x "$jdk/bin/javac" ]; then
  echo "error: Gradle JDK is missing (${GRADLE_PROPS})." >&2
  echo "       guix build openjdk:jdk   # then set org.gradle.java.home" >&2
  exit 1
fi

# Park key.properties when its keystore is absent, so the build falls back to
# the debug key instead of failing at signing time.
keyprops=android/key.properties
if [ -f "$keyprops" ]; then
  store=$(sed -n 's/^storeFile=//p' "$keyprops")
  if [ -n "$store" ] && [ ! -e "android/app/$store" ] && [ ! -e "$store" ]; then
    mv "$keyprops" "$keyprops.off"
    trap 'mv "$keyprops.off" "$keyprops" 2>/dev/null || true' EXIT
  fi
fi

# Host glibc headers must not leak into the NDK toolchain.
unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CPATH OBJC_INCLUDE_PATH LIBRARY_PATH

# Kernel headers for the native-asset hook (its clang sees a filtered env, so
# only PATH survives).
inc=$(ls -d /gnu/store/*-linux-libre-headers-*/include 2>/dev/null | head -1)
mkdir -p build/clang-wrap
if [ -n "$inc" ]; then
  for n in clang clang++ clang-23 clang++-23 cc c++; do
    src="/home/brokenshine/.guix-home/profile/bin/$n"
    [ -x "$src" ] || continue
    printf '#!/bin/sh\nexec %s -I%s "$@"\n' "$src" "$inc" > "build/clang-wrap/$n"
    chmod +x "build/clang-wrap/$n"
  done
fi

FLUTTER="$FLUTTER" PATH="$PWD/build/clang-wrap:$PATH" ./tool/build_apk.sh

version=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
mkdir -p "$OUT_DIR"
out="$OUT_DIR/droidEdit-$version-$hash.apk"
cp "build/app/outputs/flutter-apk/droidEdit-$version.apk" "$out"
printf '%s\n' "$head" > "$STAMP"
echo "nightly: $out"
