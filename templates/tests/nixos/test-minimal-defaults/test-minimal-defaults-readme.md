# test-minimal-defaults (NixOS)

Verifies safety-relevant constants defaults, derived constants, hypridle invariants and the hyprland module's effects on slim fake hosts. It does not assert which programs a real host enables.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-minimal-defaults` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-minimal-defaults/check-nixos-minimal-defaults.sh
```

Or from inside the directory:

```bash
bash check-nixos-minimal-defaults.sh
```

## How it works

`01-scenario-minimal-nixos.nix` builds three fake hosts from only the modules under test (home-manager wiring, both constants modules, `programs.hyprland`, `services.hypridle`):

- `minimal-nixos`: only `constants.user = "krit"`.
- `override-nixos`: `constants.user = "alice"` and custom hypridle timeouts (100/200/250). Acts as the control that derived values follow their inputs.
- `nowm-nixos`: `programs.hyprland.enable = false`. Acts as the control for the module gate.

Each `check-*` attribute is `"ok"` or `"FAIL: ..."` (`nix eval --raw`); `build-coexistence` is the minimal host's `home.activationPackage` (`nix build --dry-run`). The script drives both and reports pass/fail.

## Checks

| Check | Expected |
|-------|----------|
| `constants.emergencyAccess` | `false` by default |
| `screenshotsAbs` (minimal) | `/home/krit/Pictures/Screenshots` |
| `screenshotsAbs` (override) | `/home/alice/Pictures/Screenshots` |
| `primaryWallpaper.wallpaperURL` | equals `fallbackWallpaperURL` (independent option) |
| hypridle default timeouts | strictly ordered dim < lock < screenOff |
| hypridle listeners (minimal) | timeouts equal the configured options |
| hypridle listeners (override) | `[100 200 250]` |
| hypridle with no WM (nowm) | HM `services.hypridle.enable == false` |
| `security.wrappers.Hyprland.capabilities` | `""` |
| NixOS `programs.hyprland.enable` (nowm) | `false` |
| `build-coexistence` | dry-run succeeds |
