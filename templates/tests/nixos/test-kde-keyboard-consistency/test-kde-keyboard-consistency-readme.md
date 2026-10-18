# test-kde-keyboard-consistency

Guards that the Plasma keyboard settings (`modules/nixos/programs/de-wm/kde/kde-inputs.nix`, rendered by plasma-manager into `~/.config/kxkbrc`) carry the same layout, variant and options as the constants every other session uses (`constants.keyboardLayout`, `keyboardVariant`, `keyboardOptions`; Hyprland, Niri and Mango read them directly, the system console/X11 layer reads layout and variant through `services.xserver.xkb`). A Plasma session that silently drops a layout or variant switches layouts differently from the rest. Plasma deliberately sets no XKB options (batch 5 decision G11: `keyboardOptions` feeds only Hyprland, Niri and Mango; Plasma switches with its own Meta+Alt+K shortcut), so an absent `Options` key passes; if Plasma ever gets options they must equal `constants.keyboardOptions`.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-kde-keyboard-consistency` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-kde-keyboard-consistency/check-nixos-kde-keyboard-consistency.sh
```

From inside the directory:

```bash
bash check-nixos-kde-keyboard-consistency.sh
```

Eval only, no builds. `nixos-b` CI group, 5 minute cap (`test.conf`).

## How it works

`01-scenario-kde-keyboard-consistency.nix` reads `nixosConfigurations.nixos-desktop` / `nixos-laptop` (base plus every specialisation) and, for each variant with KDE enabled, the rendered `home-manager.users.<user>.programs.plasma.configFile.kxkbrc.Layout` values. Expected values are the constants of that same variant, parsed at test time (nothing is hardcoded). A missing key counts as a mismatch.

`control` builds desktop twins through `extendModules` with other layout/variant constants and checks `kxkbrc` follows them, and feeds both comparators (strict for layout/variant, unset-tolerant for options) planted mismatching and unset values.

## Checks

| Check | Expected |
|-------|----------|
| `<host>/<variant>: kxkbrc LayoutList == constants.keyboardLayout` | equal strings |
| `<host>/<variant>: kxkbrc VariantList == constants.keyboardVariant` | equal strings |
| `<host>/<variant>: kxkbrc Options unset or == constants.keyboardOptions` | unset (Plasma keeps no options by decision) or equal strings |
| `<host>/<variant>: kxkbrc LayoutList == services.xserver.xkb.layout` | Plasma and the system layer agree |
| `<host>/<variant>: kxkbrc VariantList == services.xserver.xkb.variant` | Plasma and the system layer agree |
| at least one KDE variant evaluated | non-vacuity of the positive checks |
| control: LayoutList follows constants.keyboardLayout | twin with `keyboardLayout = "us,de"`: `LayoutList` is `us,de` |
| control: VariantList follows constants.keyboardVariant | twin with another variant: `VariantList` follows |
| control: comparator rejects a mismatch | planted differing strings are not `ok` |
| control: unset-tolerant comparator still rejects a mismatch | planted differing `Options` strings are not `ok` |
| control: unset-tolerant comparator accepts an unset value | planted `null` `Options` is `ok` |
| control: comparator rejects an unset value | planted `null` is not `ok` |
