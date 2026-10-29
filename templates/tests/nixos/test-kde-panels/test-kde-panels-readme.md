# test-kde-panels

Guards that the Plasma panel in `modules/nixos/programs/de-wm/kde/kde-panels.nix` appears on every screen, identical on each. The module declares one plasma-manager panel with `screen = "all"`; plasma-manager's generated desktop script (`lib/panel.nix`, pinned) then wraps `new Panel()` in `for (screenID = 0; screenID < screenCount; screenID++)`, so every connected screen gets its own panel with the same height, location, hiding, widgets and pinned launchers. No monitor count is needed anywhere in the config.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-kde-panels` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-kde-panels/check-nixos-kde-panels.sh
```

From inside the directory:

```bash
bash check-nixos-kde-panels.sh
```

Eval only, no builds (~9 s local warm). `heavy-a` CI group (`nixos-b` has no step-budget headroom left), 5 minute cap (`test.conf`).

## How it works

`01-scenario-kde-panels.nix` reads `home-manager.users.<user>.programs.plasma.panels` and the rendered `programs.plasma.startup.desktopScript."panels".text` of a minimal KDE fixture host (`lib/fixture-host.nix`, `template-host-minimal`, KDE on, two pinned apps) and of every real-host (`nixos-desktop` / `nixos-laptop`) variant with KDE on (variants without KDE are skipped). The script is checked textually (whitespace-insensitive for the loop head).

`control` builds fixture twins (`extendModules`): one with the panel forced to `screen = 0` must fail the all-screens checks, one with KDE disabled must have no panels and no script, one with no pinned apps must have no `applications:` launchers (and the fixture must have some).

## Checks

| Check | Expected |
|-------|----------|
| `one panel entry set to screen all` | exactly one entry, `screen == "all"` |
| `script loops over every screen and creates the panel inside the loop` | one screen loop, one `new Panel()` as the first statement of its body, `lastScreen` written from `screenID` |
| `same height, location, hiding and floating on every panel` | `44`, `"bottom"`, `"autohide"`, `false`, once each in the shared panel body |
| `all widgets present once in the shared panel body` | kickoff, icontasks, pager, panelspacer, systemtray, digitalclock, showdesktop |
| `pinned launchers present in the shared panel body` | `applications:<app>` for every `programs.kde.pinnedApps` entry |
| `<host>/<variant>: <each check above>` | same on each real KDE variant (none required) |
| control: fixture has KDE on with two pinned apps | non-vacuity |
| control: a panel pinned to screen 0 fails the all-screens checks | twin is flagged |
| control: KDE disabled gives no panels and no panel script | empty |
| control: without pinned apps the script has no launchers | no `applications:` |
