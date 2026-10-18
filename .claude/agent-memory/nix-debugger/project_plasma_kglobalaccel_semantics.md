---
name: plasma-kglobalaccel-semantics
description: Plasma 6.7.5 kglobalacceld source facts - legacy <id>.desktop shortcut groups are auto-migrated to services/, shared keys fire only the lowest-serial owner, layout switcher is not a kwin action; Plasma has no XKB options by user decision
metadata:
  type: project
---

Source-read facts (kglobalacceld/kwin/plasma-workspace 6.7.5, 2026-10-18; NOT live-probed):
- `migrateConfig()` runs at every kglobalacceld start: any plain `[<id>.desktop]` group holding `keys,default,name` triplets is moved into `[services][<id>.desktop]` and deleted. plasma-manager pads non-`services/` groups to `keys,,`, so `"org.kde.spectacle.desktop"` in `programs.plasma.shortcuts` DOES work. Only breakers: same id in both forms, or a comma in a legacy key.
- Two components on one key: both keep it; `activeShortcutByKey` dispatches only the lowest serial (earliest ever registered), so Plasma defaults (klipper `plasmashell.show-on-mouse-pos` Meta+V, emojier Meta+.) likely beat later custom hotkeys.
- `Switch to Next Keyboard Layout` / `Switch to Last-Used Keyboard Layout` live in component `KDE Keyboard Layout Switcher` (Meta+Alt+K / Meta+Alt+L), never `kwin`.
- Klipper in Plasma 6 runs inside plasmashell (no klipper binary), component `plasmashell`, not `klipper`.

Plasma kxkbrc has no `Options` ON PURPOSE: batch-5 decision G11 (2026-10-13) "keyboardOptions for the 3 WMs, Plasma unchanged". Tests must accept unset Options.

**Why:** test-gap tests assumed the opposite on all three points; triaged in batch 23.
**How to apply:** check this before calling a Plasma shortcut-group or kxkbrc test failure a config bug; get kwin/kglobalacceld src via `nixosConfigurations.<h>.pkgs.kdePackages.<p>.src` (max-jobs=0 substitutes it). See [[failing-test-triage]].
