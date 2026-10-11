# test-minimal-defaults (Darwin)

Verifies that a nix-darwin host with only basic identity constants (`user`, `uid`, `hostname`, state versions) set behaves correctly.

Two things are checked:

1. **Constant defaults** - `myconfig.constants.*` fallbacks (shell, terminal, editor, catppuccin from `common/config/constants.nix`; browser, fileManager from `darwin/config/constants-darwin.nix`).
2. **home-packages body** - the module body is forced through `environment.systemPackages`, with a control host (`browser = ""`) proving the opt-out changes the result.

Eval-only test - no `nix build --dry-run` (Darwin cross-builds from Linux are heavy and slow). No stylix stub: the former tautological stylix/`enable` default checks were removed.

## Run

```bash
bash templates/tests/darwin/test-minimal-defaults/check-darwin-minimal-defaults.sh
```

Or from inside the directory:

```bash
bash check-darwin-minimal-defaults.sh
```

## How it works

`01-scenario-minimal-darwin.nix` builds two minimal denix Darwin hosts (`minimal-darwin`, `nobrowser-darwin` with `browser = ""`) from an explicit module list, then exposes `check-*` attributes as `"ok"` or `"FAIL: ..."` strings.

`check-darwin-minimal-defaults.sh` calls `nix eval --raw --impure` for each check.

## Checks

| Check | Expected |
|-------|----------|
| `constants.shell` | `"bash"` |
| `constants.terminal.name` | `"alacritty"` |
| `constants.browser` | `"firefox"` |
| `constants.editor` | `"nano"` |
| `constants.fileManager` | `"nnn"` |
| `constants.theme.catppuccin` | `false` |
| default host systemPackages | contains firefox |
| `browser = ""` host systemPackages (control) | does not contain firefox |
| `browser = ""` host `constants.browser` | `""` (override lands) |
