---
name: nix-closure-diff-pitfalls
description: How to run nix store diff-closures on NixOS toplevels and specialisations without getting wrong answers (symlink resolution, union closures, hidden sub-KiB changes, HM generation lookup)
metadata:
  type: reference
---

Pitfalls hit while diffing closures for batch 9 (2026-10-14):

- `nix store diff-closures <toplevel>/specialisation/<name>` silently diffs the MAIN toplevel: nix takes the store-path root of the argument, and `specialisation/<name>` is a symlink. Always pass `$(readlink -f <toplevel>/specialisation/<name>)`.
- The main toplevel's closure contains every specialisation's closure, so spec-only items (ProtonVPN, tailscale exitnode-warn, flatpak of specs, etc.) appear in the MAIN diff. A main-level change must be confirmed by comparing main-owned trees (etc, systemd units, HM generation), not by reading the closure diff alone.
- `nix store diff-closures` hides sub-KiB size changes (e.g. a 314 B mango config edit showed nothing in the spec diff). Use file-level comparisons (HM home-files, mango/hypr/niri text) for spec config changes.
- Name-only grouping: two different store paths with the same name (`mango-config.conf`, `networkmanager`) make size deltas that look like changes to one file. Check which store path each toplevel actually references.
- Finding a toplevel's home-manager files: `nix-store -qR | grep -- -home-manager-files | head -1` returns a SPEC's files for the main toplevel. Use `<toplevel>/etc/systemd/system/home-manager-krit.service` ExecStart -> `hm-setup-env` -> `home-manager-generation` -> `home-files`.
- `etc` and systemd units: `<toplevel>/etc` is a symlink to `<hash>-etc/etc`; `etc/systemd/system` and `etc/systemd/user` are symlinks to unit dirs. `<toplevel>/systemd` is the systemd package, not the unit set. Plain `find` (no `-L`) avoids walking the whole store.
- Laptop BEFORE for batch 9 was `n4pqgcz8wgf7fyfn8ki2mxkfcxz6k3d5` (note `w`, not `x`).

**Why:** each pitfall produced a wrong or misleading result before it was caught; the first pass wrongly reported fish/bash/rclone removals on the desktop main.

**How to apply:** any closure-diff or "what changed in spec X" task: resolve paths with readlink -f, compare main-owned trees separately from closure-union output, and check config text for changes below the closure diff threshold.
