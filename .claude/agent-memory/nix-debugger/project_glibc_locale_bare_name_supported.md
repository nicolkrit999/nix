---
name: glibc-locale-bare-name-supported
description: NixOS i18n turns every extraLocaleSettings value into "<value>/UTF-8"; UTF-8-only glibc locales (en_IN, hi_IN, en_IL...) must be written bare or glibc-locales fails "unsupported locales detected"
metadata:
  type: project
---

NixOS `i18n.supportedLocales` default is built from defaultLocale + each `extraLocaleSettings` value as `<value>/UTF-8`. glibc `localedata/SUPPORTED` lists UTF-8-only locales WITHOUT a codeset in the name (`en_IN/UTF-8`, `hi_IN/UTF-8`, `yo_NG/UTF-8`), so `LC_TIME = "en_IN.UTF-8"` yields `en_IN.UTF-8/UTF-8` and the glibc-locales `comm -13` check fails. `sanitizeUTF8Capitalization` rewrites `utf8` -> `UTF-8`, so `en_IN.utf8` fails too; only the bare `en_IN` works with the auto-derivation (nixpkgs #256688, closed, never fixed). Hit 2026-10-29 in modules/nixos/services/locale.nix (was users/krit/nixos/shared/system/swiss-locale.nix) (LC_TIME en_IN for 12h AM/PM + d/m/y).

**Why:** localedef stores `en_IN` plus an alias `en_IN.utf8`; glibc setlocale normalizes `en_IN.UTF-8`/`UTF8` -> `en_IN.utf8`, so ALL spellings resolve at runtime once the archive has `en_IN/UTF-8` (verified with glibc 2.44 `locale -a`/`date`). Python quirk: `locale.locale_alias['en_in'] = 'en_IN.ISO8859-1'`, so with LC_TIME=en_IN `getlocale(LC_TIME)` reports ISO8859-1 and `setlocale(LC_TIME, getlocale(LC_TIME))` raises "unsupported locale setting" (with en_IN.UTF-8 it round-trips). Keeping `en_IN.UTF-8` exported would need a nested `{config,pkgs,...}` module overriding `i18n.glibcLocales` with the entry remapped.

**How to apply:** for any "unsupported locales detected: xx_YY.UTF-8/UTF-8", grep the build log's SUPPORTED list for the bare `xx_YY/UTF-8` form and set the bare name; prove at runtime with `LOCALE_ARCHIVE=<built>/lib/locale/locale-archive` + the same-generation glibc `locale -a` (silent C fallback on mismatch). See [[denix-ifenabled-arg-set]] for the config-needing alternative.
