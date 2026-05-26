# test-minimal-defaults (NixOS)

Verifies that a NixOS host with only `constants.user = "krit"` set behaves correctly.

Two things are checked:

1. **Constant defaults** — all `myconfig.constants.*` fallback values match what `constants-nixos.nix` declares.
2. **Auto-enabled modules** — modules with `singleEnableOption true` or `boolOption true` are active on the minimal host. Because `hyprland` auto-enables, the full hyprland ecosystem (hyprlock, hypridle, swaync, waybar-hyprland) also activates. The dry-run build proves they all coexist.

## Run

```bash
bash templates/tests/nixos/test-minimal-defaults/check-nixos-minimal-defaults.sh
```

Or from inside the directory:

```bash
bash check-nixos-minimal-defaults.sh
```

## How it works

The scenario file `01-scenario-minimal-nixos.nix` builds a minimal denix configuration with only the auto-enabled modules in the path list, then exposes:

- `build-coexistence` — `home.activationPackage` (for `nix build --dry-run`)
- `check-*` — string `"ok"` or `"FAIL: ..."` (for `nix eval --raw`)

`check-nixos-minimal-defaults.sh` drives both types of checks and reports pass/fail with color output.

## What is checked

| Check | Expected |
|-------|----------|
| `constants.shell` | `"bash"` |
| `constants.terminal.name` | `"alacritty"` |
| `constants.browser` | `"chromium"` |
| `constants.editor` | `"nano"` |
| `constants.fileManager` | `"dolphin"` |
| `constants.theme.catppuccin` | `false` |
| `programs.hyprland.enable` | `true` |
| `myconfig.stylix.enable` | `true` |
| `services.swaync.enable` | `true` |
| `services.hyprlock.enable` | `true` |
| `services.hypridle.enable` | `true` |
| `programs.waybar-hyprland.enable` | `true` |
| `build-coexistence` | dry-run succeeds |
