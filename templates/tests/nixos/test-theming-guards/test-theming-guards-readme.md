# test-theming-guards

Guards the stylix / Qt / GTK / portal-env / hyprlock theming rules (host enablement choices are not asserted; the NixOS-level stylix qt target is deliberately not checked, only the HM-side one, which is the gotcha's subject) from the gotcha docs `stylix-qt-kde-gtk-theming.md` and `xdg-desktop-portal-nixos.md`, on the real hosts.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-theming-guards` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-theming-guards/check-nixos-theming-guards.sh
```

Or from inside the directory:

```bash
bash check-nixos-theming-guards.sh
```

Eval only; both hosts are evaluated in parallel, 76 s inside the full parallel suite run of 2026-10-11.

## How it works

`01-scenario-theming-guards.nix` loads the real flake and, per host (`HOST` env), builds four variants of `nixosConfigurations.<host>` with `extendModules`: `base`, `catppuccin-on`, `catppuccin-off` (forces `myconfig.constants.theme.catppuccin`) and `light` (forces `polarity`). Forcing both modes makes every conditional check able to fail. Expected values are always derived from an independent source (the `myconfig` constants, host/module `myconfig.stylix.targets` overrides), never hardcoded per host. It prints `variant<TAB>check<TAB>ok|FAIL: ...` lines.

`check-nixos-theming-guards.sh` runs both hosts in parallel and prints a per-check PASS/FAIL list; exit 1 on any failure.

The `files` section of the report adds one extra eval of the host with catppuccin off and `myconfig.constants.wallpapers = []`, to check the hyprlock lock background falls back to the shared fallback wallpaper constant.

Hyprlock text lints only apply in base16 mode (catppuccin mode hands hyprlock to the catppuccin module); in that mode the check asserts the catppuccin hyprlock target instead. The `##` in `foreground="##..."` is correct hyprlang escaping of a literal `#`, so the check asserts the escaped form is present.

## Checks

Per host, per variant:

| Check | Expected |
|-------|----------|
| HM `stylix.targets.qt.enable` | `false` |
| `stylix.targets.kde.enable` | `== !catppuccin` |
| targets bat/lazygit/starship/gtk/hyprlock/hyprland/swaync/tmux | `== !catppuccin` unless `myconfig.stylix.targets.<n>.enable` overrides |
| targets gnome/waybar/rofi/wofi/neovim | `false` |
| `gtk3`/`gtk4` `gtk-application-prefer-dark-theme` | 1 if dark, 0 if light |
| NixOS and HM `stylix.polarity` | equal the constant |
| `catppuccin.enable`/`autoEnable` (system and HM) | `true`/`false` |
| HM / NixOS env / systemd global env | none of `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `XDG_SESSION_TYPE` |
| `QT_QPA_PLATFORMTHEME` | `kde` iff hyprland or kde enabled, else `qt5ct` |
| qt6ct `color_scheme_path` | points at a declared `xdg.dataFile` Breeze file matching polarity |
| `programs.plasma.overrideConfig` | `true` when KDE enabled |
| `catppuccin.hyprlock.enable` | `== catppuccin` (when a WM is on) |
| hyprlock `rgba(...)` (base16 mode) | at least one, all 8 lowercase hex digits |
| hyprlock `foreground="##rrggbbaa"` (base16 mode) | escaped `##` form present, no single `#` |

Fallback (host with catppuccin off and empty `wallpapers`):

| Check | Expected |
|-------|----------|
| hyprlock `background` path (when a WM is enabled) | equals `fetchurl` of `constants.fallbackWallpaperURL`/`SHA256` |
