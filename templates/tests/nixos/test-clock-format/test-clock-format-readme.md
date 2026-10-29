# test-clock-format

Checks the `use24HourClock` option of `services.sddm-astronaut`, `services.sddm-pixie` and `services.hyprlock` on the **built outputs** of fixture hosts built from scratch.

Why it exists: these three clocks ignore `LC_TIME` (one locale carries clock, date order, names and week start, so `LC_TIME` cannot be split, and the greeter and the lock screen render their own format). Each has its own bool: `false` (default) = 12-hour, `true` = 24-hour. The test pins:

- a host that does not set the option and a host that sets the default (`false`) give the same output;
- `true` gives 24-hour, and the options are independent of each other in one host;
- `themeConfig.HourFormat` (astronaut) and `themeConfig.use24HourClock` (pixie) win over the option;
- both hyprlock variants (catppuccin and plain) use the **same** clock token and the **same** date format, extracted from the real generated outputs; if the upstream catppuccin theme changes its DATE format this is the intended alarm;
- the pixie theme's date line is patched to day-first and its hour logic still switches on `config.use24HourClock !== "true"` (otherwise the option would silently become a no-op after a pinned-revision bump);
- the astronaut build fails (instead of silently staying 24-hour) when the theme conf has no `HourFormat` line.

`sddm-pixie` is disabled on both real hosts (`sddm-astronaut` is the greeter there), so only this fixture exercises it. `sddm-astronaut` and `hyprlock` values of the real hosts are asserted in `nixos-host-invariants`.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-clock-format     # from the repo root
bash check-nixos-clock-format.sh                                # from this folder
```

Expected result: PASS. 21 fixture twins (about 1 min of evaluation), then a dozen or so small distinct builds (patched themes, generated lock confs, pixie themes with and without a background, the upstream references). Cap 12 min, group `heavy-b`.

## How it works

1. `01-scenario-clock-format.nix` loads the real modules `sddm-astronaut`, `sddm-pixie`, `hyprlock`, the catppuccin HM wiring and the stylix module into two fixture hosts (`host/astronaut.nix`, `host/pixie.nix`; neither mentions `use24HourClock`, which a check enforces). `myconfig.programs.hyprland.enable` is a plain option sink (`shared/nixos-extra/option-sinks.nix`) because that is all hyprlock reads. Each scenario is an `extendModules` twin; the catppuccin variant flips `constants.theme.catppuccin`. It exposes one link farm `all` (`meta.json` plus one link per built output) so a single `nix build` evaluates every twin once.
2. `check-nixos-clock-format.sh` builds `all`, builds the one scenario that must fail separately, and runs `assert_clock.py`. If the farm does not build, the script builds every attribute alone to name the failing one.
3. `assert_clock.py` reads only built files (the astronaut `Themes/<theme>.conf`, the pixie `theme.conf`, `Main.qml` and `components/Clock.qml`, the generated lock conf) plus the evaluated plain lock labels, and compares against the unpatched upstream references built from the same package.

### Clock matrix

Columns are what the fixture host specifies; "unset" means the host does not mention the option (module default `false`). Every row is evaluated in the plain lock variant and, for the first five rows, in the catppuccin variant too (`<name>-cat`).

| Scenario | astronaut | hyprlock | Expected result |
|----------|-----------|----------|-----------------|
| (a) `unset` | unset | unset | astronaut `hh:mm AP`, lock `$TIME12` |
| (b) `explicit-default` | `false` | `false` | identical derivations and bytes to (a) |
| (c) `both24` | `true` | `true` | astronaut keeps upstream `HourFormat`, lock `$TIME` |
| (d) `astro24-lock12` | `true` | unset | astronaut 24-hour, lock `$TIME12` |
| (e) `astro12-lock24` | unset | `true` | astronaut `hh:mm AP`, lock `$TIME` |
| `cyber-12h`, `cyber-24h` | unset / `true` | unset | same as (a) / (c) for the `cyberpunk` theme (not theme specific) |
| `override-hourformat` | `false` + `themeConfig.HourFormat = "HH:mm:ss"` | unset | `HourFormat="HH:mm:ss"` |
| `stub-with-key`, `stub-missing-key` | unset (overlay: stub `sddm-astronaut` with / without an `HourFormat` line) | unset | builds and is patched / the build fails with "HourFormat not applied" |

Pixie scenarios (own host, hyprlock plain variant evaluated in the same host):

| Scenario | pixie | hyprlock | Expected `theme.conf` / lock |
|----------|-------|----------|-----------------------------|
| `pixie-unset` | unset | unset | `use24HourClock=false`, lock `$TIME12` |
| `pixie-explicit-default` | `false` | `false` | identical derivation and bytes to `pixie-unset` |
| `pixie24-lock12` | `true` | unset | `use24HourClock=true`, lock `$TIME12` |
| `pixie12-lock24` | unset | `true` | `use24HourClock=false`, lock `$TIME` |
| `pixie-override-true` | `false` + `themeConfig.use24HourClock = "true"` | unset | `use24HourClock=true` |
| `pixie-override-false` | `true` + `themeConfig.use24HourClock = "false"` | unset | `use24HourClock=false` |
| `pixie-bg-unset`, `pixie-bg-24` | unset / `true` | unset | as `pixie-unset` / `pixie24-lock12`, with a `background` (the build then also patches the QML) |

## Checks

Global:

| Check | Expected |
|-------|----------|
| scenario set is non-empty and every derivation built | all themes, pixie themes, lock confs and the three upstream references exist |
| fixture hosts do not mention `use24HourClock` | so "unset" really is the module default |

Per astronaut scenario (`unset`, `explicit-default`, `both24`, `astro24-lock12`, `astro12-lock24`, `cyber-12h`, `cyber-24h`, `override-hourformat`):

| Check | Expected |
|-------|----------|
| option value | the effective `sddm-astronaut.use24HourClock` equals the matrix row |
| `HourFormat` line | exactly one: `"hh:mm AP"` for 12-hour, the upstream reference's own line for 24-hour, the `themeConfig` value for the override |
| themeConfig wins (override) | the line is the override and not `hh:mm AP` |
| AM/PM marker | the format has one exactly when 12-hour |

Across astronaut scenarios:

| Check | Expected |
|-------|----------|
| 12-hour vs 24-hour conf (`unset`/`both24`, `cyber-12h`/`cyber-24h`) | differ in the `HourFormat` line only |
| other embedded theme | another theme's conf in the same package is identical in both builds (only the active theme is patched) |
| guard control | the stub theme WITH an `HourFormat` line builds and is patched to `hh:mm AP` |
| guard | the stub theme WITHOUT one fails the build with "HourFormat not applied" |
| (a)=(b) astronaut, lock catppuccin, pixie | `unset` and `explicit-default` have the same derivation and the same built bytes |
| control(a)=(b) | `true` changes the astronaut, lock and pixie derivations |
| mixed rows really mix | (d) is astronaut 24 / lock 12, (e) the reverse |

Per pixie scenario (8):

| Check | Expected |
|-------|----------|
| option value | the effective `sddm-pixie.use24HourClock` equals the table |
| `theme.conf` | exactly one `use24HourClock=` line with the table value (themeConfig wins in the override rows) |
| `Main.qml` date | contains `"dddd, d MMMM"` once and no `"dddd, MMMM d"`, with and without a background |
| `Clock.qml` | still contains `if (config.use24HourClock !== "true") {` once and `hours = hours % 12;`, and no AM/PM marker word |

hyprlock, per plain scenario (all non-stub astronaut and pixie scenarios), per catppuccin scenario (5) and across variants:

| Check | Expected |
|-------|----------|
| option value | the effective `hyprlock.use24HourClock` equals the table |
| plain clock label | exactly `$TIME12` (12-hour) or `$TIME` (24-hour), no `cmd[...]` and no `<span>` |
| plain date label | exactly one label with a `date +'...'` command |
| catppuccin `# TIME` text | exactly the same token |
| catppuccin vs the theme | the generated `# TIME` text equals the theme's own exactly when 24-hour |
| catppuccin `# DATE` | exactly one `date +"..."` command |
| cross-variant equality (5 cases) | clock token and `date +` format string are equal in the plain label and the generated catppuccin conf |

Controls (the checks above can fail):

| Check | Expected |
|-------|----------|
| control(cross) 12-hour conf vs 24-hour plain clock | the cross check reports a clock difference |
| control(cross) month-first DATE in the conf | reported as a date difference |
| control(cross) month-first plain date label | reported as a date difference |
| control(cross) both clock states occur | both `$TIME` and `$TIME12` appear in the plain and in the catppuccin scenarios |
| control(format helper) | `hh:mm AP` has an AM/PM marker, `HH:mm` and `HH:mm:ss` do not |
| control(diff helper) | a second changed line is reported, not only `HourFormat` |
