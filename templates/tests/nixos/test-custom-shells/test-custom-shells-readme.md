# test-custom-shells

Unit tests for shell/waybar activation logic (caelestia, noctalia, waybar variants).

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix` file
evaluates a scenario and asserts on the resulting config (packages present, assertions
firing, keybinds correct, etc.) without building anything.

## Run all tests

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/test-custom-shells
```

Or from inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## Run a single test file manually

```bash
nix run github:danielefongo/nix-tests -- conflict/01-two-shells-on-hyprland_test.nix
```

## Test categories

| Prefix | What it checks |
|--------|---------------|
| `conflict/` | Assertions that must fire when two conflicting modules are both active |
| `positive/` | Valid combinations that must NOT fire any assertion |
| `dormant-flag/` | Shell enabled but `enableOnWM = false` — must behave like no shell |

## Wallpaper note

The Hyprland scenarios set one `wallpapers` entry (`shared/one-wallpaper.nix`) so the
`hyprland-wallpaperd` supervisor is present or suppressed depending on shell ownership.
With `wallpapers = [ ]` the supervisor is never started, so the check would be vacuous.
