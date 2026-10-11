# test-screenshot-folder-consistency

Asserts that every DE/WM/shell that can take screenshots resolves to the same destination folder (exact, case-sensitive), so e.g. `Screenshots` vs `screenshots` drift between desktops cannot come back.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-screenshot-folder-consistency` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-screenshot-folder-consistency/check-nixos-screenshot-folder-consistency.sh
```

Or from inside the directory:

```bash
bash check-nixos-screenshot-folder-consistency.sh
```

Eval only; the four variants are evaluated in parallel.

## How it works

`01-scenario-screenshot-folder-consistency.nix` takes `VARIANT` from the env and builds one system:

- `nixos-desktop` and `nixos-laptop`: the real hosts (together they enable hyprland, mango, niri, gnome, kde, cosmic).
- `synthetic-caelestia` and `synthetic-noctalia`: `nixos-laptop` extended with kde and niri forced off and only that one shell forced on (neither shell is enabled on a real host). Only what the test needs is toggled.

From the evaluated config it extracts every screenshot destination that is enabled in that variant: the HM activation `mkdir`, `home.sessionVariables.XDG_SCREENSHOTS_DIR` (mango/cosmic), the hyprland `hyprland.lua` env entry, the caelestia `execOnce` command, mango `autostart_sh` and the `mango-screenshot` script, niri `environment` and `screenshot-path`, the gnome `launch-screenshot` script, and KDE `spectaclerc` (both locations). Script bodies are read from the script derivation (`.drv`), not built. Each source is tagged with whether its context expands `$HOME` (shell scripts, session variables: yes; hyprland env, niri settings, KDE config: no). `$HOME` is then normalised to the evaluated home directory, `file://` and a trailing `/` are stripped, and the expected value is the shared constant `myconfig.constants.screenshots`, normalised the same way. noctalia has no screenshot configuration of its own, so its variant only guards that nothing diverges through the generic sources.

`check-nixos-screenshot-folder-consistency.sh` runs the variants in parallel, prints a per-check PASS/FAIL list, and additionally asserts the resolved destination is the identical string across all variants. Exit 1 on any failure.

## Checks

Per variant:

| Check | Expected |
|-------|----------|
| Every enabled screenshot-capable DE/WM has an extracted destination | none missing (guards against the extraction silently finding nothing) |
| All destinations identical after `$HOME` normalisation | at most one distinct value |
| Destinations equal the shared constant | equal to the normalised `myconfig.constants.screenshots` |
| No literal `$HOME` where it is not expanded | none in hyprland env, niri settings, KDE config |
| `[<source>] equals shared destination` (one per extracted source) | equal to the normalised constant |

Across variants:

| Check | Expected |
|-------|----------|
| Shared destination identical across all variants | exact same string |

Limitation: cosmic shares `home.sessionVariables.XDG_SCREENSHOTS_DIR` with mango, so its coverage is only that variable.
