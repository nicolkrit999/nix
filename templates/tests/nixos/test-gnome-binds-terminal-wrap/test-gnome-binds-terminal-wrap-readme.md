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

`01-scenario-gnome-binds-terminal-wrap.nix` has two parts.

- Fixture (`mkNixos` on `template-host-minimal`, see `templates/tests/lib/fixture-host.nix`): only `programs.gnome.enable = true` plus fixed constants (`terminal.name = kitty`, `fileManager = yazi`, `editor = gedit`, `terminalApps = [ yazi hx ]`). The rendered `dconf.settings` custom keybinding entries "Launch File Manager" and "Launch editor" must follow them. The positive checks and every control are built here, so they never depend on which DE a real host enables. Controls are twins of the fixture (`extendModules`) with forced constants (GUI file manager, TUI editor, `terminalApps = []`, another terminal name); each twin also fails if GNOME is not on.
- Real hosts (`nixos-desktop`, `nixos-laptop`, base plus every specialisation): for each variant that has GNOME enabled, the same two commands must equal the expectation derived from that host's own constants at test time (cross-file consistency). A host or variant without GNOME contributes no checks and that is not an error; non-vacuity is provided by the fixture.

The module has no `terminal.exec` constant; the wrap is the `terminal.name -e <app>` string. Planted wrong expectations must be rejected.

## Checks

| Check | Expected |
|-------|----------|
| `fixture: TUI file manager is wrapped in the terminal` | `kitty -e yazi` |
| `fixture: GUI editor is launched bare` | `gedit` |
| `<host>/<variant>: Launch File Manager (fileManager=...)` | for every real GNOME variant: command is `<terminal> -e <app>` when the app is in `terminalApps`, else the bare app |
| `<host>/<variant>: Launch editor (editor=...)` | same for the editor role |
| control: GUI file manager is launched bare | fixture twin with `fileManager = "nautilus"`: command `nautilus` |
| control: TUI editor is wrapped in the terminal | twin with `editor = "hx"`: `kitty -e hx` |
| control: TUI role is launched bare once it leaves terminalApps | twin with `terminalApps = []`: `yazi` unwrapped |
| control: wrapper uses constants.terminal.name | twin with `terminal.name = "wezterm"`: `wezterm -e yazi` |
| control: expectation rejects a bare TUI command | planted expectation differs from a bare `yazi` |
| control: expectation rejects a wrapped GUI command | planted expectation differs from `kitty -e nautilus` |
