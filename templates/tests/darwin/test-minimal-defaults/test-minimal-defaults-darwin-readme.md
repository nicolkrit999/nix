# test-minimal-defaults (Darwin)

Verifies that a nix-darwin host with only basic identity constants (`user`, `uid`, `hostname`, state versions) set behaves correctly.

Two things are checked:

1. **Constant defaults** — all `myconfig.constants.*` fallback values match what `constants-darwin.nix` declares.
2. **Auto-enabled modules** — `stylix` (`boolOption true`) and `home-packages` (`singleEnableOption true`) are active on a minimal Darwin host.

Eval-only test — no `nix build --dry-run` (Darwin cross-builds from Linux are heavy and slow).

## Run

```bash
bash templates/tests/darwin/test-minimal-defaults/check-darwin-minimal-defaults.sh
```

Or from inside the directory:

```bash
bash check-darwin-minimal-defaults.sh
```

## How it works

`01-scenario-minimal-darwin.nix` builds a minimal denix Darwin configuration with the auto-enabled modules in the path list, then exposes `check-*` attributes as `"ok"` or `"FAIL: ..."` strings.

`check-darwin-minimal-defaults.sh` calls `nix eval --raw --impure` for each check.

## What is checked

| Check | Expected |
|-------|----------|
| `constants.shell` | `"bash"` |
| `constants.terminal.name` | `"alacritty"` |
| `constants.browser` | `"firefox"` |
| `constants.editor` | `"nano"` |
| `constants.fileManager` | `"nnn"` |
| `constants.theme.catppuccin` | `false` |
| `myconfig.stylix.enable` | `true` |
| `home-packages.enable` | `true` |
