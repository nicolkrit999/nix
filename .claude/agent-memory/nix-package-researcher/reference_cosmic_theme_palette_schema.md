---
name: cosmic-manager theme palette schema
description: cosmic-manager appearance.theme/toolkit option tree, fixed palette slot names (CosmicPaletteInner), Builder->build-theme flow, no catppuccin/stylix cosmic target
metadata:
  type: reference
---

cosmic-manager (locked rev f7e32c4b, store xw9gymgnhq0yhhyrpvfgs7svbak2b4s0-source) themes COSMIC through `wayland.desktopManager.cosmic.appearance.*`.

- `theme.mode` enum dark|light -> `CosmicTheme.Mode` `is_dark`.
- `theme.dark` / `theme.light` (nullable, default null) -> written as `CosmicTheme.{Dark,Light}.Builder` (version 2); `home.activation.buildCosmicTheme` then runs `cosmic-ctl build-theme` (cosmic-ext-ctl 1.6.0, nixpkgs) which produces `CosmicTheme.{Dark,Light}`.
- Builder fields: accent (srgb), bg_color (srgba), destructive, success, warning, text_tint, neutral_tint, primary/secondary_container_bg (srgba), window_hint (srgb), active_hint (u32), gaps (u32 pair), corner_radii (radius_0/xs/s/m/l/xl, 4-float tuples), spacing (space_none..space_xxxl, ints), palette (RON tuple-enum Dark|HighContrastDark|HighContrastLight|Light wrapping a full palette).
- Palette slots (fixed names, arbitrary RGB allowed): bright_red, bright_green, bright_orange, gray_1, gray_2, neutral_0..neutral_10, accent_blue, accent_indigo, accent_purple, accent_pink, accent_red, accent_orange, accent_yellow, accent_green, accent_warm_grey, ext_warm_grey, ext_orange, ext_yellow, ext_purple, ext_indigo, ext_pink, ext_blue, plus free-form `name`. No ext_red/ext_green. COSMIC has no named accent presets, only these slots.
- `toolkit` (-> `com.system76.CosmicTk` v1): apply_theme_global, header_size, icon_theme (default "Cosmic" when set), interface_density (Compact|Spacious|Standard), interface_font / monospace_font {family, stretch, weight, style}, show_maximize, show_minimize.
- Every option defaults to null (defaultNullOpts); nothing is written unless set.
- `wallpapers` (filter_by_theme etc.) lives in modules/wallpapers.nix. No cursor option in cosmic-manager.
- No catppuccin-nix cosmic target (catppuccin modules: nixos, home-manager, darwin, lib; pkgs has no cosmic). No stylix cosmic target (stylix modules list has no cosmic). nixpkgs search "cosmic catppuccin" returns no catppuccin COSMIC theme.
- Repo clash point: modules/nixos/toplevel/cosmic.nix writes CosmicTk interface_font/monospace_font via a system linkFarm under share/cosmic (stylix-derived). A cosmic-manager `toolkit` with fonts writes the user config, which overrides it silently.

Why: research for matching catppuccin flavor/accent in COSMIC (2026-10-29).
How to apply: any COSMIC theming work starts from this schema; verify cosmic-ctl's Builder->palette derivation before claiming exact palette fidelity (not verified from source).
