# test-plasma-shortcut-groups

Guards the plasma-manager `programs.plasma.shortcuts` group names in `modules/nixos/programs/de-wm/kde/kde-binds.nix`. plasma-manager writes every attribute name straight into `kglobalshortcutsrc`. Components that are desktop files live in the nested group `services][<id>.desktop`, which plasma-manager spells `services/<id>.desktop`. A plain `<id>.desktop` group is the Plasma 5 form: plasma-manager pads it to a `keys,,` triplet and kglobalacceld 6.7.5 (`migrateConfig()`, run at every daemon start) moves it into `services][<id>.desktop` and deletes it, so both spellings reach KDE. What breaks the migration is the same id in both forms (the legacy entries overwrite or duplicate the services ones) or a comma inside a legacy key (the triplet no longer splits into 3 fields and the entry is skipped).

The other two checks: `Switch to Next Keyboard Layout` is registered by KWin under the `KDE Keyboard Layout Switcher` component (kwin 6.7.5 `keyboard_layout.cpp`), so an entry under `kwin` is inert; and a custom hotkey on a Plasma default key (`Meta+V` = `plasmashell` `show-on-mouse-pos`, klipper in plasmashell; `Meta+.` = `services/org.kde.plasma.emojier.desktop` `_launch`) shares the key with the default owner. kglobalacceld then dispatches only the lowest-serial (earliest registered) shortcut, so one of the two never fires.

**Allow-list:** `Meta+V` and `Meta+.` clash on purpose: verified live 2026-10-18 on the laptop (Plasma 6.7.5): vicinae wins (Meta+V opens the vicinae clipboard, Meta+. the vicinae emoji picker), although kglobalacceld normally lets the first registered owner win. `allowedClashes` in the scenario excuses exactly these two pairs. An entry only applies while the default owner (group + action) matches; any other hotkey on a Plasma default whose owner is not released still fails.

**Expected failure until merged:** the `Switch to Next Keyboard Layout is not filed under kwin` check fails on the KDE variants while `kde-binds.nix` still sets `kwin."Switch to Next Keyboard Layout"` (the line is being deleted in the main tree). It is a real check, no workaround.

**Sources:** the names and the dispatch rule come from the pinned sources (kwin, kglobalacceld, plasma-workspace, plasma-desktop 6.7.5); the two vicinae hotkeys were verified live (see Allow-list). Update the `defaultOwners` table if a live probe (kglobalshortcutsrc / `qdbus org.kde.kglobalaccel`) shows otherwise.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-plasma-shortcut-groups` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-plasma-shortcut-groups/check-nixos-plasma-shortcut-groups.sh
```

From inside the directory:

```bash
bash check-nixos-plasma-shortcut-groups.sh
```

Eval only, no builds. `nixos-b` CI group, 5 minute cap (`test.conf`).

## How it works

`01-scenario-plasma-shortcut-groups.nix` reads `nixosConfigurations.nixos-desktop` / `nixos-laptop` (base plus every specialisation) and, for each variant with KDE enabled, the evaluated `programs.plasma.shortcuts` and `programs.plasma.hotkeys.commands` of the home-manager user.

`control` builds a desktop twin (`extendModules`, `mkOverride 10` on `programs.plasma.shortcuts`) that adds the `services/` prefix and releases the two default owners; the checks must pass there. Planted group sets prove the group predicate accepts a legacy-only group and rejects a doubled id and a comma key, and that a layout switcher filed under `kwin` is flagged.

## Checks

| Check | Expected |
|-------|----------|
| `<host>/<variant>: legacy .desktop groups migrate cleanly into services/` | no `<id>.desktop` group is also set as `services/<id>.desktop`, and no legacy group key contains a comma |
| `<host>/<variant>: Switch to Next Keyboard Layout is not filed under kwin` | the action is not set under `kwin` (it belongs to the `KDE Keyboard Layout Switcher` component) |
| `<host>/<variant>: custom hotkeys do not shadow an unreleased Plasma default` | a hotkey on `Meta+V` / `Meta+.` only exists when its default owner is set to `none`, except the allow-listed `Meta+V` (`plasmashell.show-on-mouse-pos`) and `Meta+.` (`services/org.kde.plasma.emojier.desktop._launch`) (table from the pinned sources, not live-verified) |
| at least one KDE variant evaluated | non-vacuity of the positive checks |
| control: services/-prefixed groups pass | twin with prefixed groups: no problem groups, KDE still on |
| control: legacy-only .desktop group is accepted | planted `org.kde.spectacle.desktop` alone is not reported |
| control: same desktop id in legacy and services/ form is flagged | planted pair is reported |
| control: comma key in a legacy .desktop group is flagged | planted `Meta+,` in `org.kde.krunner.desktop` is reported |
| control: released defaults pass the collision check | twin with the two defaults set to `none`: no collisions |
| control: collision check sees Meta+V and Meta+. when not allow-listed or released | empty allow-list, planted hotkeys, empty shortcuts report both keys |
| control: allow-listed Meta+V and Meta+. pass | real allow-list, same planted hotkeys: no collisions |
| control: allow-list entry no longer applies when the default owner differs | owner table with a changed action: Meta+V is reported again |
| control: a new clash with a Plasma default (invented key) still fails | invented default `Meta+F12` unreleased is reported, allow-listed Meta+V is not |
| control: a released invented default passes | invented default set to `none`: no collision |
| control: layout switcher under kwin is flagged | planted `kwin."Switch to Next Keyboard Layout"` is reported |
| control: layout switcher in its own component is accepted | planted `"KDE Keyboard Layout Switcher"` entry is not reported |
