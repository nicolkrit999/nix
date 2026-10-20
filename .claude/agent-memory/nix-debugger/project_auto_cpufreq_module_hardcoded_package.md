---
name: auto-cpufreq-module-hardcoded-package
description: upstream auto-cpufreq nixosModule hardcodes inputs.self.packages (no package option, overlay ignored); patch by re-importing nix/module.nix with a fake self
metadata:
  type: project
---

The auto-cpufreq flake input's `nix/module.nix` is `inputs: {...}` and uses only `inputs.self.packages.${system}.default`. No `package` option exists, and a nixpkgs overlay does not reach it. It is also NOT nixpkgs' auto-cpufreq (nixpkgs ships an older version with its own `services.auto-cpufreq` module and already has `pythonRelaxDeps = [ "urwid" ]`).

To patch the package, modules/nixos/services/power/auto-cpufreq.nix imports `"${inputs.auto-cpufreq}/nix/module.nix"` with `{ self.packages = mapAttrs (... overridePythonAttrs ...) inputs.auto-cpufreq.packages; }`.

2026-10-20: added `pythonRelaxDeps = [ "urwid" ]` (upstream pyproject `urwid = "^3.0.2"` vs nixpkgs urwid 4.0.11). urwid is only used by the `--monitor`/`--stats` TUI (system_monitor.py); a smoke test against 4.0.11 rendered fine with no warnings.

**Why:** the input is unpinned `?ref=master`, so its deps drift with every nixpkgs bump.
**How to apply:** for future dependency-cap failures in auto-cpufreq, extend the same overridePythonAttrs. Drop the wrapper and go back to `inputs.auto-cpufreq.nixosModules.default` once upstream pyproject allows urwid 4.
