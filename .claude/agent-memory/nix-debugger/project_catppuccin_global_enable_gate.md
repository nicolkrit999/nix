---
name: catppuccin-global-enable-gate
description: catppuccin/nix main gates every port on `catppuccin.enable && port.enable`; repo had only per-port enables, so ports silently became no-ops (only symptom was the autoEnable warning)
metadata:
  type: project
---

catppuccin/nix main (from ~2026-10) gates each port on `config.catppuccin.enable && cfg.enable`. The old release branch gated on `cfg.enable` only. This repo turns ports on one at a time (`catppuccin.<port>.enable = myconfig.constants.theme.catppuccin`) and never set the global `catppuccin.enable`. After the input bump, every port evaluated to nothing (`programs.bat.config.theme = null`) with no error. The only sign was the "will soon auto enroll ports ... catppuccin.autoEnable" warning.

**Why:** a theme regression that fails silently is easy to dismiss as warning noise. In `modules/common/themes/catppuccin.nix` the fix sets `enable = true; autoEnable = false;` in both `nixos.always` and `home.always`.

**How to apply:** if catppuccin theming "disappears" after an input bump, check `catppuccin.enable`/`autoEnable` at both the system and HM levels before anything else. Never "silence" the autoEnable warning by setting it to false without also setting `enable = true`. Verify with a targeted eval of a port's effect, e.g. `home-manager.users.krit.programs.bat.config.theme`.
