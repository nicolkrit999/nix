# test-locale

Pins the contract of the generic `services.locale` module (`modules/nixos/services/locale.nix`) on a fixture host built from scratch (only that module plus the constants schema), and proves the bare-name spelling trap with the real `i18n.glibcLocales` build.

Why it exists:

- **Fallback and off switch.** Enabled without values, all nine `LC_*` categories and the display-manager `LC_TIME` are `en_US.UTF-8`; disabled, nothing is written.
- **`LC_TIME` cannot be split.** One locale carries the 12/24-hour clock, the date order, the day and month names and the first weekday, so `time` is one string and the display manager gets exactly that value (`mkDefault`, so a plain definition still wins). The sddm-astronaut, sddm-pixie and hyprlock clocks ignore `LC_TIME` and have their own `use24HourClock` option (see `nixos-clock-format`).
- **Bare-name trap (nixpkgs#256688).** NixOS builds `i18n.supportedLocales` as `"<value>/UTF-8"`, but glibc lists UTF-8-only locales as `en_IN/UTF-8`. `time = "en_IN"` builds; `time = "en_IN.UTF-8"` makes the glibc-locales build fail with "unsupported locales detected". Only the real build proves it, so the test builds `config.i18n.glibcLocales` and also pins the failing spelling. When nixpkgs fixes the issue, the negative build starts to succeed, the test goes red on purpose, and the module docs and the host comments need updating.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-locale     # from the repo root
bash check-nixos-locale.sh                                # from this folder
```

Expected result: PASS. Seven evaluations of the fixture host (base plus six twins) plus three `i18n.glibcLocales` builds (about 20 s each; the failing one stops at the check), a few seconds of runtime probes.

## How it works

1. `01-scenario-locale.nix` builds one fixture host (`shared/host-locale.nix`: `services.locale.enable = true`, nothing else) and `extendModules` twins that set the option values (`mkOverride 10` where the base defines the option). `checks` is a map of `"ok"` / `"FAIL: ..."` strings; `locales.{us,host,bad}` are the `i18n.glibcLocales` derivations of the no-values, host-style (eight `it_CH.UTF-8`, `time = "en_IN"`) and wrong-spelling (`time = "en_IN.UTF-8"`) twins; `tools` is a tiny derivation linking the glibc `locale` binary and coreutils `date` of the same pkgs.
2. `check-nixos-locale.sh` prints the eval checks, builds the three archives (the failing one is expected to fail and its log is searched for the glibc message), then probes the built archives with `env -i LOCALE_ARCHIVE=<archive> locale -a` and `date` (`TZ=UTC`, fixed instant 2026-10-29 21:05). `env -i` and `locale -a` matter: on NixOS an unknown locale falls back to the system archive or to C silently, so presence is proven by the archive listing and the formats are compared against the C fallback.

## Checks

Eval checks (fixture host twins):

| Check | Expected |
|-------|----------|
| defaults: nine LC_* | enabled with no values: exactly the nine `LC_ADDRESS` ... `LC_TIME` keys, all `en_US.UTF-8` |
| defaults: display-manager LC_TIME | `en_US.UTF-8` |
| disabled | no `LC_*` key in `i18n.extraLocaleSettings` and no `LC_TIME` in the display-manager environment |
| control(disabled) | the enabled host does write both (so the disabled result is not an unloaded module) |
| host values: categories | eight categories `it_CH.UTF-8`, `time` the bare `en_IN` |
| host values: display-manager LC_TIME | `en_IN` |
| host values: supportedLocales | contains `en_IN/UTF-8` and `it_CH.UTF-8/UTF-8`, does not contain `en_IN.UTF-8/UTF-8` |
| control(spelling) | `time = "en_IN.UTF-8"` maps to `en_IN.UTF-8/UTF-8` and has no `en_IN/UTF-8` |
| wiring | nine distinct values (asserted distinct) each reach their own `LC_*` key, so a swapped category fails |
| partial | only `time` set: the other eight stay `en_US.UTF-8`, display manager `en_IN` |
| display-manager LC_TIME is a mkDefault | a plain `systemd.services.display-manager.environment.LC_TIME` definition wins without a conflict |
| control(checker) | the comparison helper rejects a wrong expectation (swiss values vs `en_US`, disabled vs `en_US`, defaults vs swiss) |
| tools | the `glibcLocales` version equals the pkgs `glibc` version used for `locale` |

Build and runtime checks:

| Check | Expected |
|-------|----------|
| host archive builds | `i18n.glibcLocales` of the host-style twin builds (bare `en_IN` accepted by glibc) |
| control archive builds | `i18n.glibcLocales` of the no-values twin builds |
| `time = en_IN.UTF-8` | the build FAILS with "unsupported locales detected" (a success means nixpkgs#256688 is fixed: update the docs and this test) |
| unsupported list | names `en_IN.UTF-8/UTF-8` |
| glibc's SUPPORTED list | the printed list spells it `en_IN/UTF-8 \` |
| `locale -a` host archive | prints entries (glibc and archive versions agree), lists `en_IN`, `it_CH.utf8`, `en_US.utf8` |
| control(archive) | the no-values archive lists `en_US.utf8` but neither `en_IN` nor `it_CH.utf8` |
| `LC_ALL=en_IN` | `date` prints `29/10/26` and a 12-hour `09:05:00 PM` time |
| `LC_ALL=en_IN.UTF-8` | same output as the bare `en_IN` (every spelling resolves once the archive has it) |
| `LC_ALL=it_CH.UTF-8` | `29.10.2026\|21:05:00` (dotted date, 24-hour time) |
| control(locale) | the C fallback prints `10/29/26\|21:05:00`, so a silent C fallback would fail the en_IN check |
