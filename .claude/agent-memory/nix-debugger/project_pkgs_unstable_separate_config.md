---
name: pkgs-unstable-separate-config
description: pkgs-unstable imports in this repo are separate nixpkgs instances that do NOT inherit the host's nixpkgs.config (allowUnfree/permittedInsecurePackages) unless config is forwarded
metadata:
  type: project
---

`users/krit/nixos/shared/system/virtualisation.nix` (and any other `import inputs.nixpkgs-unstable { ... }` site) creates a **fresh, separate nixpkgs instance**. The host's `nixpkgs.config` - including `permittedInsecurePackages` (set repo-wide via `programs.nltchNur.permittedInsecurePackages` → wired in `modules/common/programs/nltch-nur.nix`) and `allowUnfree` - is applied only to the *main* `pkgs`. It does NOT reach the imported `pkgs-unstable` unless you explicitly forward it with `inherit (pkgs) config;`.

**Why:** In 2026-07 a `winboat-0.9.0` (from `pkgs-unstable`) → `electron-40.10.5` insecure-package failure burned three debug rounds. Two prior fixes (host-level `permittedInsecurePackages`, and overlay reroutes of claude-desktop.nix / google-antigravity.nix) all missed it because none touched the separate nixpkgs import. The `--show-trace` frame that finally proved it: `system-path` → list element index 8 → `winboat-0.9.0` → `buildPhase` (`-c.electronDist=${electron.dist}`). The `services/desktop-managers/gnome.nix` / `environment.sessionVariables` frames near the truncation were a lazy-eval red herring (just the walk through `system-path`).

**How to apply:** For any insecure/unfree failure whose trace bottoms out in a package from `pkgs-unstable` (or any `import inputs.nixpkgs-* {}`), the fix is at the import site: `inherit (pkgs) config;` - NOT the host `permittedInsecurePackages` alone. To confirm a culprit, eval `(import inputs.nixpkgs-unstable { system="x86_64-linux"; }).<pkg>.drvPath` (fails) vs `... config = hostpkgs.config; }` (succeeds). Related denix wiring: [[feedback-delib-home-ifenable-patterns]].
