# test-mango-option-names

Regression guard for the mango 0.18.0 snake_case keyword rename: the generated mango settings and the rendered `config.conf` text must contain none of the pre-0.18.0 keyword names, and monitor rules must render under `monitor_rule`.

## Run

From repo root:

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/test-mango-option-names
```

From inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## How it works

`01-mango-option-names/host.nix` is a fake desktop host with only mango enabled (two monitors, one `disable:1`, two extra window rules, one `windowRulesOnce` rule). It reuses `shared/eval-scenario.nix` and the static wallpaper constants from `test-nixos-wallpapers`, so that test directory must stay in place.

`mango-option-names_test.nix` reads `wayland.windowManager.mango.settings`, and renders it at eval time with the mango flake's own `toMango` generator (`nix/lib.nix`), without building anything and without running `mango -p` (that is covered by the real `config.conf` derivation build). Keys are extracted from the rendered `key = value` lines and compared against the removed names (the 31 keys from the 0.18.0 rejection list) and the removed window-rule sub-fields.

## Checks

### M01 - mango settings use only 0.18.0 keyword names

| Check | Expected |
|-------|----------|
| settings attrset keys intersect the old-name list | empty |
| rendered `config.conf` keys intersect the old-name list | empty |
| rendered text yields more than 10 keys (parser sanity) | true |
| no `window_rule` entry uses `appid`, `isfloating`, `isnoanimation`, `isnoshadow`, `noblur`, `isopensilent` | true |
| `window_rule` entries use `app_id:` and `is_floating:` | true |
| `monitor_rule` has 2 entries and is a rendered key | true |
| a `monitor_rule` entry for HDMI-A-1 carries `disable:1` | true |
| `tag_rule` and `layer_rule` are rendered keys | true |
| `window_rule_once` is set, rendered, free of old sub-fields, uses `app_id:` | true |
| `window_rule` entries use none of the full 0.18.0 old sub-field list | true |
| old-sub-field detector flags a legacy rule (self-check) | true |
| `tag_rule` has no `nmaster`/`mfact`; `layer_rule` has no `noblur`/`noanim`/`noshadow` | true |
| `bind`, `bindl`, `bindsl` are all rendered keys | true |
| Pause/Play are exactly 2 entries in `bindsl` and absent from `bindl` | true |
| volume and brightness keys are in `bindl` | true |
| the retired plain `binds` key is not rendered | true |
| `SUPER+CTRL+Left` is `resizewin`, no `SUPER+CTRL+Left` `focusmon` | true |
| `SUPER+SHIFT+1` is `tagsilent`, `SUPER+ALT+1` is `tag` | true |
| `SUPER+S` is `toggle_special_tag` | true |
| no `btn_middle` mousebind | true |
