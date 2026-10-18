# test-gnome-binds-terminal-wrap

Guards the GNOME custom keybindings for the file-manager and editor roles (`modules/nixos/programs/de-wm/gnome/gnome-binds.nix`): a TUI app (`constants.terminalApps`, e.g. `yazi`, `nvim`) must be launched through the terminal (`<constants.terminal.name> -e <app>`), a GUI app must be launched bare. Without the wrapper a TUI bind would start a process with no tty and do nothing visible.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-gnome-binds-terminal-wrap` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-gnome-binds-terminal-wrap/check-nixos-gnome-binds-terminal-wrap.sh
```

From inside the directory:

```bash
bash check-nixos-gnome-binds-terminal-wrap.sh
```

Eval only, no builds. `nixos-b` CI group, 5 minute cap (`test.conf`).

## How it works

`01-scenario-gnome-binds-terminal-wrap.nix` reads `nixosConfigurations.nixos-desktop` / `nixos-laptop` (base plus every specialisation), and for each variant with GNOME enabled reads the rendered `dconf.settings` custom keybinding entries "Launch File Manager" and "Launch editor". The expected command is derived from the same constants at test time (`terminalApps`, `terminal.name`, `fileManager`, `editor`), so the test does not depend on which apps a host picks. The module has no `terminal.exec` constant; the wrap is the `terminal.name -e <app>` string.

`control` builds twins of the desktop through `extendModules` with forced constants (GUI file manager, TUI editor, `terminalApps = []`, another terminal name) and checks the rendered command follows them; planted wrong expectations must be rejected.

## Checks

| Check | Expected |
|-------|----------|
| `<host>/<variant>: Launch File Manager (fileManager=...)` | for every GNOME variant: command is `<terminal> -e <app>` when the app is in `terminalApps`, else the bare app |
| `<host>/<variant>: Launch editor (editor=...)` | same for the editor role |
| at least one GNOME variant evaluated | non-vacuity of the positive checks |
| control: GUI file manager is launched bare | twin with `fileManager = "nautilus"`: command `nautilus` |
| control: TUI editor is wrapped in the terminal | twin with `editor = "hx"`: command `<terminal> -e hx` |
| control: TUI role is launched bare once it leaves terminalApps | twin with `terminalApps = []`: `yazi` unwrapped |
| control: wrapper uses constants.terminal.name | twin with `terminal.name = "wezterm"`: `wezterm -e yazi` |
| control: expectation rejects a bare TUI command | planted expectation differs from a bare `yazi` |
| control: expectation rejects a wrapped GUI command | planted expectation differs from `kitty -e nautilus` |
