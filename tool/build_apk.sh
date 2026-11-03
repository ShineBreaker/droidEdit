#!/usr/bin/env bash
# Path-agnostic APK build used by tool/release_android.sh locally and by
# .github/workflows/build-release.yml on CI. Env vars:
#   FLUTTER   — flutter binary (default: flutter on PATH)
#   VERSION   — version string from pubspec.yaml (default: auto-detected)
# Output:
#   build/app/outputs/flutter-apk/droidEdit-<version>.apk
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER=${FLUTTER:-flutter}
version=${VERSION:-$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)}
[ -n "$version" ] || { echo "no version in pubspec.yaml" >&2; exit 1; }

# The in-app updater matches assets named droidEdit-<version>.apk — keep the
# naming in lockstep with lib/platform/app_updater.dart's _apkName regex.
out="build/app/outputs/flutter-apk/droidEdit-$version.apk"
unset OSUEDIT_DEV  # release is the real app, not the .dev one
"$FLUTTER" pub get
"$FLUTTER" build apk --release --target-platform android-arm64
mkdir -p "$(dirname "$out")"
cp build/app/outputs/flutter-apk/app-release.apk "$out"
echo "built $out"
echo "$out"
