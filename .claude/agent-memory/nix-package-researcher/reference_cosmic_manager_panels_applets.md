---
name: cosmic-manager panels/applets facts
description: cosmic-manager (locked store path xw9gymgnhq...) panel options, app-list favorites, file writes, overwrite semantics, output default Virtual-1; COSMIC 1.11 panel binary facts
metadata:
  type: reference
---

cosmic-manager source: /nix/store/xw9gymgnhq0yhhyrpvfgs7svbak2b4s0-source

- Panels: `wayland.desktopManager.cosmic.panels` (list of submodules, freeform attrs). Keys: name (required str), anchor (Bottom|Left|Right|Top), anchor_gap, margin (u32), opacity (0-1), output (Active | All | Name [list], default Name ["Virtual-1"]), size (XS..XL), background (Dark|Light|ThemeDefault|Color), expand_to_edges, autohide (null or {handle_size, transition_time, wait_time}), plugins_wings (tuple [left right]), plugins_center (list).
- No dock option: a dock is just another panel entry named "Dock" (file `com.system76.CosmicPanel.Dock`). Panel-button `configs` has a "Dock" key.
- App list applet: `wayland.desktopManager.cosmic.applets.app-list.settings.{favorites, enable_drag_source, filter_top_levels}`. Default favorites: firefox, com.system76.CosmicFiles/Edit/Term/Settings. Written to `com.system76.CosmicAppList` only if any setting is non-null.
- Time applet: `applets.time.settings.{military_time, show_seconds, show_weekday, show_date_in_top_panel, first_day_of_week}`.
- Files written: `com.system76.CosmicPanel` (entries = list of names) and `com.system76.CosmicPanel.<name>` (whole panel struct), applets as `com.system76.<Applet>`. All go through `configurations.json` applied by `cosmic-ext-ctl apply` in `configureCosmic` (files.nix); the panel module then `killall .cosmic-panel-wrapped` after that. Writes are full-file "write" operations, not merges.
- Repo does not use `wayland.desktopManager.cosmic.panels` anywhere yet (only binds/input/idle/wallpaper).
- The `panels` default is a single "Panel" entry; setting `panels` replaces it wholesale, so the full plugin lists must be restated.

COSMIC 1.11 binaries (cosmic-panel 1.11.0, cosmic-session 1.11.0 in store): default-config code is compiled in; "Falling back to default panel configuration" when entries missing. Exact Dock default NOT verified (no source in store). Known applet ids: CosmicPanelWorkspacesButton, CosmicPanelAppButton, CosmicPanelLauncherButton, CosmicAppList, CosmicAppletMinimize, A11y, InputSources, StatusArea, Tiling, Audio, Network, Battery, Notifications, Bluetooth, Power, Time, Workspaces.

Repo pinned apps: hosts/*/default.nix `pinnedApps` (full `.desktop` filenames, resolved via desktopMap); KDE/GNOME consume them. COSMIC favorites use app ids without `.desktop` in cosmic-manager examples; stripping the suffix is the safe mapping (not verified against cosmic-applets source).

Why: needed to judge a declarative COSMIC panel/dock layout (2026-10). How to apply: verify output name on hardware before declaring; expect GUI panel edits to be overwritten at each activation.
