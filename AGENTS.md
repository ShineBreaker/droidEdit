# droidEdit

Flutter osu! beatmap editor (package `osu_edit`). Apache-2.0; the sibling
`../osu-droid` repo is Apache-2.0 too, so its code may be referenced, but
prefer re-deriving behaviour from ppy/osu (lazer) — `ObjectVisuals` already
documents the lazer sources each animation follows.

## Build / test on this machine (Guix)

- Flutter is not in PATH: `/home/brokenshine/Programs/flutter-sdk/bin/flutter`.
- `flutter analyze` works as-is. `flutter test` first runs the
  `flutter_soloud` build hook, which compiles C++ with Guix clang; that clang
  misses the Linux kernel headers (`linux/errno.h` …). Also, hook child
  processes get a filtered environment (`includeParentEnvironment: false`),
  so `CPATH` etc. never reach clang — only whitelisted vars like `PATH` do.
  Workaround: wrap clang in a PATH dir that injects `-I`:

  ```sh
  mkdir -p /tmp/clang-wrap
  for n in clang clang-23 clang++ clang++-23 cc c++; do
    printf '#!/bin/sh\nexec <real-clang> -I<linux-libre-headers>/include "$@"\n' \
      > /tmp/clang-wrap/$n && chmod +x /tmp/clang-wrap/$n
  done
  PATH=/tmp/clang-wrap:$PATH flutter test
  ```

  (`<linux-libre-headers>` = e.g.
  `/gnu/store/…-linux-libre-headers-6.12.17/include`.) Hook results are cached
  in `.dart_tool/hooks_runner` — delete it when changing the toolchain setup.

- Some touch-gesture tests (axis_scale, pattern_tools, slider_bounds,
  home_screen) fail in this environment even on a clean checkout — they are
  pre-existing environment issues, not regressions.
