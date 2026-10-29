---
name: scenario-eval-and-locale-probe-traps
description: denix fixture traps (host.pkgs, mkMerge twins, tryEval limits, drv names for equality, link-farm single eval) and the LOCALE_ARCHIVE probe recipe (env -i, locale -a) learned writing test-locale / test-clock-format
metadata:
  type: feedback
---

- Denix fake host: pkgs of the host is `hosts.<name>.pkgs` (NOT `config.nixpkgs.pkgs`, `config._module` missing). A `lib.mkMerge [...]` is not a module: wrap as `{ config = lib.mkMerge [...]; }` for `extendModules { modules = [ ... ]; }`. Twin must `mkOverride 10` any option the base host sets (embeddedTheme, constants.*), not options the host leaves at the default.
- `builtins.tryEval` does NOT catch "attribute missing" errors, only throw/assert; a `guard` wrapper cannot turn a missing option into a FAIL string.
- drvPath-equality checks ("host sets the default == host leaves it unset"): derivation names must be scenario independent (`runCommand "lock-conf"`, not `"lock-conf-${name}"`), otherwise equal content still gives different drvs.
- One-eval pattern for many twins: expose a `pkgs.linkFarm` with `meta.json` (`pkgs.writeText (toJSON meta)`) plus one link per built output; one `nix build all` evaluates every twin once (21 twins ~70 s on the laptop; evaluating meta and building separately doubles it). Keep a per-attribute fallback only for failures. Expected-fail builds (grep guard) are separate `nix build` calls of just that attr (cheap, lazy).
- Locale archive probing: bash tool env sets LOCALE_ARCHIVE/LC_*; use `env -i LOCALE_ARCHIVE=<out>/lib/locale/locale-archive <glibc.bin>/bin/locale -a` (glibc `locale` of the same pkgs; mismatched glibc silently lists nothing). `date` with an unknown locale falls back to the system archive (/run/current-system) or C, so presence proof = `locale -a`, format proof = `TZ=UTC LC_ALL=en_IN date -d '2026-10-29 21:05:00' '+%x|%X'` -> `29/10/26|09:05:00 PM UTC` (C gives `10/29/26|21:05:00`, it_CH `29.10.2026|21:05:00`).
- `nix build ... --option log-lines 2000` to keep glibc's "unsupported locales detected" in stderr (the supported list printed before it is long).
- Smoke-test an assertion script offline: build fake output dirs from existing store paths (old patched themes, catppuccin hyprlock source) and run it before the checker does; found a drv-name bug that way.

**Why:** each cost one eval round (60+ s, 8 GB on the laptop) or would have shipped a vacuous/failing check.
**How to apply:** any new denix-fixture test with twins, any test that reads built derivation outputs, any locale/i18n test.
