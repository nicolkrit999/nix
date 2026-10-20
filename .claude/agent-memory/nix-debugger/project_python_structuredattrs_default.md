---
name: python-structuredattrs-default
description: nixpkgs buildPython* defaults __structuredAttrs=true (since lock f3a73bcf / 09063bd1, 2026-10); makeWrapperArgs strings with ${...} are no longer shell-evaluated
metadata:
  type: project
---

mk-python-derivation.nix now has `__structuredAttrs ? true` (absent at lock 26f4107e). makeWrapperArgs becomes a real bash array, so wrap.sh passes `"${qtWrapperArgs[@]}"` literally -> makeCWrapper `#error Unknown argument ${qtWrapperArgs[@]}` (wrapQtAppsHook pulls makeBinaryWrapper). Hit by school.nix moodle-dl override 2026-10-20.

**Why:** any override/local python pkg using `makeWrapperArgs = [ "\${var}" ]` or `"--prefix X : $foo"` strings breaks the same way.

**How to apply:** use `preFixup = ''makeWrapperArgs+=("''${qtWrapperArgs[@]}")'';` (nixpkgs pattern, e.g. androguard). Sweep: `grep -rn 'makeWrapperArgs.*\\\$' --include=*.nix`. Side trap: agent shells may carry a stale python3.13 PYTHONPATH (vulnix) - smoke-test python binaries with `env -u PYTHONPATH`, else bogus cffi version-mismatch tracebacks.
