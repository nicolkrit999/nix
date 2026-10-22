---
name: python-structuredattrs-default
description: nixpkgs buildPython* defaults __structuredAttrs=true (since lock f3a73bcf / 09063bd1, 2026-10); makeWrapperArgs strings with ${...} are no longer shell-evaluated
metadata:
  type: project
---

mk-python-derivation.nix now has `__structuredAttrs ? true` (absent at lock 26f4107e). makeWrapperArgs becomes a real bash array, so wrap.sh passes `"${qtWrapperArgs[@]}"` literally -> makeCWrapper `#error Unknown argument ${qtWrapperArgs[@]}` (wrapQtAppsHook pulls makeBinaryWrapper). Hit by school.nix moodle-dl override 2026-10-20. Also hits UNMODIFIED nixpkgs pkgs (gearlever 3.4.7, still broken on master 2026-10-20: `"\${gappsWrapperArgs[@]}"` + one-string `"--prefix PATH : ..."` - the latter is a 2nd error since structuredAttrs elements are argv words, not split). Fixed via overlay in hosts/nixos-desktop/local-packages.nix.

**Why:** any override/local python pkg using `makeWrapperArgs = [ "\${var}" ]` or `"--prefix X : $foo"` strings breaks the same way.

**How to apply:** use `preFixup = ''makeWrapperArgs+=("''${qtWrapperArgs[@]}")'';` (nixpkgs pattern, e.g. androguard). Sweep: `grep -rn 'makeWrapperArgs.*\\\$' --include=*.nix`. Side trap: agent shells may carry a stale python3.13 PYTHONPATH (vulnix) - smoke-test python binaries with `env -u PYTHONPATH`, else bogus cffi version-mismatch tracebacks.

Eval side effect: structuredAttrs python drvs now carry an `env` attrset (`{ LANG }`), so `p ? env` no longer identifies a python env. Broke the test-ai-tool-modules `isPyEnv` heuristic (`... || p ? pythonPath && p ? env`) -> false "headroom adds python env(s): headroom-ai-*" (pre-existing on HEAD 336d2452, 2026-10-21). Real `python3.withPackages` envs have NO `pythonPath` but their `env` is a DERIVATION (structuredAttrs `env` is a plain attrset): discriminate with `lib.isDerivation (p.env or null)`. Fixed in the test 2026-10-22.
