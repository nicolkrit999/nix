---
name: pkgs-unstable-separate-config
description: any separately imported nixpkgs instance (e.g. `import inputs.nixpkgs-stable {}`, a flake input's own packages.<system>) does NOT inherit the host's nixpkgs.config unless config is forwarded
metadata:
  type: project
---

A **fresh, separate nixpkgs instance** (`import inputs.<nixpkgs-input> { ... }`, or a flake input's own `packages.<system>.foo`) gets none of the host's `nixpkgs.config`. The host's `permittedInsecurePackages` (repo-wide via `programs.nltchNur.permittedInsecurePackages` in `modules/common/programs/nltch-nur.nix`) and `allowUnfree` only reach the *main* `pkgs`.

Today the only such import is `pkgsStableFor` in `flake.nix` (nixpkgs-stable, `config.allowUnfree = true` only, no `permittedInsecurePackages`). A package pulled via `pkgsStable` that is insecure/EOL fails even when the host permits it; forward the host config (`inherit (pkgs) config;`) or extend the import's `config` when adding such a pin.

**Why:** in 2026-07 a `winboat-0.9.0` -> `electron-40.10.5` insecure-package failure, then coming from a separate `import inputs.nixpkgs-unstable {}` (since removed by the unstable switch), burned three debug rounds. Host-level `permittedInsecurePackages` and overlay reroutes of claude-desktop / google-antigravity all missed it because none touched the separate import. The `--show-trace` frame that proved it: `system-path` -> list element -> `winboat-0.9.0` -> `buildPhase` (`-c.electronDist=${electron.dist}`); the `gnome.nix` / `environment.sessionVariables` frames near the truncation were a lazy-eval red herring.

**Corollary:** `programs.nltchNur.permittedInsecurePackages = [ "electron-40.10.5" ]` in both Linux hosts was once live (for winboat) and was wrongly judged stale by checking only the generic `electron` attribute. Audit such entries against the specific package's own dependency (`electron_40` for winboat) in the locked nixpkgs, and after the unstable switch re-verify with a targeted `nix eval` before keeping or dropping it.

**How to apply:** for an insecure/unfree failure whose trace bottoms out in a package from a separately imported nixpkgs, fix at the import site (`inherit (pkgs) config;`), not only at host level. Confirm by evaluating `.<pkg>.drvPath` on the bare import (fails) vs with `config = hostpkgs.config;` (succeeds). Related denix wiring: [[feedback-delib-home-ifenable-patterns]].
