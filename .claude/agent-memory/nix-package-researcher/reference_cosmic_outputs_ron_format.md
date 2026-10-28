---
name: cosmic-outputs-ron-format
description: COSMIC per-monitor config lives in ~/.local/state/cosmic-comp/outputs.ron keyed by the exact set of connected connectors; cosmic-manager has no outputs option; cosmic-randr 1.11.0 is the apply path
metadata:
  type: reference
---

COSMIC stores display settings in `$XDG_STATE_HOME/cosmic-comp/outputs.ron` (not cosmic-config). Upstream: pop-os/cosmic-comp `src/config/mod.rs` (load_dynamic, read_outputs, write_outputs) and `cosmic-comp-config/src/output/comp.rs` (OutputsConfig, OutputConfig, OutputInfo).

- Top-level `config: HashMap<Vec<OutputInfo>, Vec<OutputConfig>>`. Key = sorted list of `(connector, make, model)` for the exact set of connected outputs; value = per-output configs in the same order. Exact set match: a different monitor set falls back to the auto layout (packed left to right, sorted by connector name).
- Refresh is in mHz (`Some(143999)` = 143.999 Hz). Position is `(u32, u32)`, so negative offsets cannot be stored.
- `enabled` is `r#true` / `r#false` / `Mirroring("CONNECTOR")`.
- Load failure (RON parse error) makes cosmic-comp delete the file and reset.
- Written on every Settings/cosmic-randr change and on fallback hotplug, rewriting the whole file (in-memory map). Read-only symlink write failures only log a warning.

cosmic-manager (locked rev f7e32c4b): no outputs/displays option in modules/compositor.nix. Only `wayland.desktopManager.cosmic.{configFile,dataFile,stateFile}` raw entries, applied by `cosmic-ctl apply` in home.activation `configureCosmic`. These are cosmic-config `version`+`entries` shapes, so outputs.ron is not expressible there (unverified how cosmic-ctl maps state components to paths).

Apply path: `cosmic-randr` (nixpkgs 1.11.0, at /run/current-system/sw/bin/cosmic-randr) subcommands: enable, disable, mirror, list [--kdl], mode <out> <w> <h> [--refresh Hz --scale --transform --pos-x --pos-y --adaptive-sync always|automatic|disabled --test], position, xwayland --primary, kdl (stdin).

Live (2026-10-28, nixos-desktop): connected DP-1 (ASUS PG32UCDP, 3840x2160@240.016, scale 1.5, pos 1440,325, xwayland primary), DP-2 (LG 27GN950, 3840x2160@143.999, scale 1.5, rotate90, pos 0,0), HDMI-A-1 (JetKVM v1, disabled). Matching key is the 4-connector entry with JetKVM on HDMI-A-1.

**Why:** the user asked for declarative monitor setup; the answer determines whether a Nix-declared file survives.
**How to apply:** prefer a cosmic-randr user service or activation seed over a read-only home.file symlink; per-set keys mean each monitor combination needs its own entry.
