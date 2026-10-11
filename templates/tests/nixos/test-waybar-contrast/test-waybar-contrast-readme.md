# test-waybar-contrast

Checks that the three waybars (`waybar-hyprland`, `waybar-niri`, `waybar-mango`, modules under
`modules/nixos/programs/waybar/`) stay readable on extreme base16 themes. The CSS and the bar config
are generated from `config.lib.stylix.colors`, so a scheme whose slots do not fit the fixed
"base05 on base01" assignment shows up here. The assumption: if these four extremes behave, every
scheme in between does too. "Light"/"dark" is stylix **polarity**, not how the colors look.

| Scenario | Polarity | Scheme | Why it is an extreme |
|----------|----------|--------|----------------------|
| `windows-nt-light` | light | Windows NT Light | lightest scheme |
| `unikitty` | light | Unikitty (base00 `#ff7ad3`) | darkest-looking light scheme |
| `ocean` | dark | Ocean (base00 `#224fbc`) | lightest-looking dark scheme |
| `darkviolet` | dark | Dark Violet | darkest scheme |

Palettes are vendored inline in `templates/tests/lib/scheme-{windows-nt-light,unikitty,ocean,darkviolet}.nix`
(MIT, tinted-theming schemes-spec 0.11; only base00-base0F, base24's base10-base17 are not read by
waybar or stylix here). `catppuccin-mocha` is the positive control; `synthetic-flat` is the all-grey edge case.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-waybar-contrast      # from the repo root
bash check-nixos-waybar-contrast.sh                            # from this folder
```

The test is expected to PASS: the waybar styling is contrast-aware (`modules/nixos/programs/waybar/contrast-lib.nix`).
Text falls back to black/white when no theme slot reaches 4.5:1, and accents are tinted toward black or
white until they reach 3:1. A red result is a finding about the waybar styling. Do not loosen the thresholds.

## How it works

1. `01-scenario-waybar-contrast.nix` takes the real `nixos-desktop` (it already enables all three
   WMs and their waybars, so no enablement is changed) and builds one `extendModules` variant per
   scheme that only overrides `stylix.base16Scheme` and `stylix.polarity` (system and home-manager
   side) with `mkForce` and an inline attrset (no IFD, no store reads). It emits the generated
   `style.css` and bar config text for each WM plus the palette.
2. `contrast.py` does the CSS work in Python:
   - resolves `@define-color`, builds a small GTK-like cascade (selector matching with descendant /
     child combinators, `#id`, `.class`, `:hover`, `:not()`, specificity then source order) over a
     waybar node chain (`window#waybar > box > box.modules-* > widget > module`), so
     `#workspaces button.active label`, `#battery.critical:not(.charging)`, `tooltip label` etc.
     resolve like in the real stylesheet;
   - derives the elements from the bar config (every module listed in `modules-left/center/right`),
     expanding workspace states (default, hover, active, active+hover, urgent, focused) and battery
     states (normal, each `states` key, charging, critical+charging);
   - for each element checks the cascaded foreground against the effective background (nearest
     opaque `background-color` up the chain) as **text, >= 4.5:1**, and every pango
     `<span color=..>` in `format*`, `exec`, `rewrite` and `tooltip-format*` strings as an
     **icon/accent, >= 3:1** (battery picks `format-critical` / `format-charging` like waybar does;
     spans with their own `background=` use it). Mango's tag line is a shell/awk script, so its
     `-v active_bg/active_fg/occupied/empty` colors are parsed out (a parse failure is a FAIL);
   - translucent backgrounds are composited over white and over black and the worse ratio is used;
   - an element with no opaque background (drawn on the wallpaper) is a `WARN` line, not a failure
     (none exist today: every module has a `base01` pill; invisible `opacity: 0` nodes are skipped).
     The wallpaper is a single constant, not picked per theme or polarity.
3. Output: one line per scheme x WM x element, then a `PASS/FAIL/WARN` matrix.

Modelling assumptions (waybar internals, not verifiable statically): `hyprland|niri/workspaces` and
`hyprland|niri/window` are `box` nodes, every other module is a `label` that also draws its own
background; workspace text is the `label` inside `button`.

## Checks

| Check | Expected |
|-------|----------|
| text contrast (workspace states, clock, window, language, weather, wifi, bluetooth, pulseaudio, mic, battery states, notification, tags, tooltip) | >= 4.5:1 for every scenario and the mocha control |
| span / icon accent contrast | >= 3:1 |
| `@define-color baseXX` equals the scheme palette | override really reached the generated CSS |
| `stylix.polarity` (system and home-manager) equals the scenario polarity | override took effect |
| each WM yields >= 12 elements from >= 5 modules | extraction is not vacuous |

Edge scenario (real config):

| Scenario | Expected |
|----------|----------|
| `synthetic-flat` (all 16 slots `#777777`, zero usable theme slots) | 0 FAIL on all three WMs, and every passing text element resolved to `#000000`/`#ffffff` (proves the fallback ran, not a vacuous pass) |

Checker controls (synthetic CSS + bar config fed through `analyse()`, the same cascade/extraction path as the real scenarios, no real config involved):

| Control | Expected |
|---------|----------|
| text fg == bg | FAIL |
| span fg == bg | FAIL |
| text at 4.4:1 / 4.6:1 | FAIL / PASS |
| span at 2.9:1 / 3.1:1 | FAIL / PASS |
| span at 4.4:1 | PASS (icon threshold is 3:1, not 4.5) |

Other controls:

| Control | Expected |
|---------|----------|
| `catppuccin-mocha` through the same pipeline | 0 FAIL |
| ratio black/white = 21, equal colors = 1 | math is right |
| translucent black bg + white fg | worst-case (over white) backdrop fails 4.5 |
| no opaque background | `WARN`, not PASS |
| cascade unit cases (id > class > `*`, `:hover`, `:not()`, later rule wins) | selector engine is right |
