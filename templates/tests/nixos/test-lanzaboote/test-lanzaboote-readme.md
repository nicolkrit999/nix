# test-lanzaboote

Pins the contract of the generic `services.lanzaboote` module (`modules/nixos/services/lanzaboote.nix`) on a fixture host built from scratch: the module under test, the constants schema and a stub `services.impermanence` option, nothing else.

Why it exists:

- **Keys must survive a reboot.** With impermanence the root is a tmpfs, so a `pkiBundle` outside `/persist/` loses the signing keys and the machine cannot sign new generations. The module asserts this, and the test proves the assertion fires only with impermanence on (including the `/persistent/...` prefix trap) and not otherwise.
- **One bootloader.** lanzaboote replaces the bootloader install hook; GRUB enabled next to it must fail an assertion, and `systemd-boot` must stay forced off.
- **Declared Secure Boot.** `secureBoot` only declares that the firmware enforces Secure Boot: it needs `enable`, and with it an initrd root shell (`boot.initrd.systemd.emergencyAccess`) is rejected. Both assertions are proven to fire (and to stay silent when the property holds).
- **Console mode.** `consoleMode` feeds `boot.lanzaboote.settings."console-mode"` (default `keep`); only `keep`, `auto`, `max` and digit strings are accepted, anything else fails an assertion, and the other `loader.conf` keys (`default`, `editor`, `timeout`) stay lanzaboote's own.
- **Manual key handling.** Keys are created and enrolled by hand with `sbctl`: `autoGenerateKeys`, `autoEnrollKeys` and `measuredBoot` stay off, `sbctl` is installed, `/etc/sbctl/sbctl.conf` points `sbctl` at the same `pkiBundle` as lanzaboote (without it `sbctl` falls back to `/var/lib/sbctl`, which is tmpfs), and the directory is pre-created root-only.

The host side of the contract (which bootloader branch each real host satisfies, GRUB hook gating, the borgmatic exclusion of the key directory) lives in `nixos-host-invariants`, `nixos-grub-efi-sync` and `nixos-borg-backup-config`. Which host enables the module is deliberately not asserted anywhere.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-lanzaboote     # from the repo root
bash check-nixos-lanzaboote.sh                                # from this folder
```

Expected result: PASS. About 30 s of evaluation (fixture host plus about thirty `extendModules` twins) and one tiny build (the `remarshal` YAML generation of `sbctl.conf`, twice).

## How it works

1. `01-scenario-lanzaboote.nix` builds the fixture host (`shared/host-lanzaboote.nix`: only `constants.user`; `shared/impermanence-stub.nix` declares `myconfig.services.impermanence.enable`; `inputs` is passed through `specialArgs` so `inputs.lanzaboote` resolves). Twins set the module options (including `secureBoot`, `consoleMode` and `boot.initrd.systemd.emergencyAccess`), force `boot.loader.grub.enable`, turn the stub impermanence on, or define `boot.loader.systemd-boot.enable` / the lanzaboote key options directly. `checks` maps a name to `"ok"` or `"FAIL: ..."`; `bundles` exposes the two `pkiBundle` values; `etcSource.{default,custom}` are the `/etc/sbctl/sbctl.conf` derivations of the default and custom twins.
2. Assertions are read from `config.assertions`: only failing entries whose message contains `services.lanzaboote` are counted, then split by the grub, persist, consoleMode, secureBoot-enable and emergencyAccess message fragments.
3. `check-nixos-lanzaboote.sh` prints the eval checks, builds both `sbctl.conf` derivations and compares the realised file: line 1 must be exactly `%YAML 1.1` and line 2 exactly `---` (the header `pkgs.formats.yaml` writes; lanzaboote's own `sbctl.conf` has the same one and `sbctl` parses it); those two lines are dropped, and the remaining lines, sorted, must be exactly `guid: <bundle>/GUID` and `keydir: <bundle>/keys` (no quote stripping). The eval checks also read the attrset the file is generated from (`source.value`), so the eval level and the realised file agree.

Fake data only: the bundle paths are made-up directories, no key or fingerprint exists anywhere in the test.

## Checks

Eval checks (fixture host and twins):

| Check | Expected |
|-------|----------|
| defaults: lanzaboote off | module off: `boot.lanzaboote.enable` false |
| defaults: nothing written | module off: no `sbctl/sbctl.conf` in `environment.etc`, no tmpfiles rule mentioning `sbctl`, no `sbctl` package |
| defaults: pkiBundle | `/persist/var/lib/sbctl` |
| defaults: configurationLimit | 10 |
| defaults: secureBoot | false (module off and enabled) |
| defaults: consoleMode | option `keep`, and `settings."console-mode"` `keep` when enabled |
| defaults: other loader.conf keys | `settings` minus `console-mode` has exactly the keys `default`, `editor`, `timeout` and equals the module-off value |
| control(off) | the enabled twin does write sbctl.conf, a tmpfiles rule, the package and lanzaboote (the off result is not an unloaded module) |
| enabled: lanzaboote on | `boot.lanzaboote.enable` true |
| enabled: defaults propagate | `boot.lanzaboote.pkiBundle` and `configurationLimit` equal the module defaults (`/persist/var/lib/sbctl`, 10) |
| enabled: custom values propagate | a custom `pkiBundle` and `configurationLimit = 3` reach `boot.lanzaboote` |
| enabled: configurationLimit 5 | a limit of 5 reaches `boot.lanzaboote.configurationLimit` (differs from the default) |
| consoleMode: 5 | `consoleMode = "5"` gives `settings."console-mode" = "5"`; the other `loader.conf` keys equal the default twin's |
| consoleMode: valid values | `keep`, `auto`, `max`, `5`, `0`, `12` fire no assertion and propagate unchanged |
| consoleMode: invalid values | `abc`, `-1`, empty, `5x`, `keepx`, ` 5` (leading space) each fail exactly the consoleMode assertion |
| consoleMode: message | the assertion message names the offending value |
| control(consoleMode) | an invalid and a valid value yield different failure counts; an invalid mode while the module is off fires nothing and is not written to `settings` |
| enabled: systemd-boot forced false | a plain `boot.loader.systemd-boot.enable = true` still evaluates to false |
| control(systemd-boot) | the same plain definition without the module stays true |
| enabled: sbctl package | `pkgs.sbctl` is in `environment.systemPackages` |
| enabled: tmpfiles rule | exactly `d <pkiBundle> 0700 root root -` for the default and the custom bundle |
| control(tmpfiles) | the custom twin carries only the custom rule, the default twin only the default rule |
| enabled: sbctl.conf attrs | exactly `keydir = <bundle>/keys` and `guid = <bundle>/GUID` for the default and the custom bundle (same bundle as lanzaboote) |
| control(sbctl.conf) | default and custom contents differ |
| enabled: key options off | `autoGenerateKeys`, `autoEnrollKeys`, `measuredBoot` false |
| control(keys) | a twin enabling the three options reads true for all |
| assertions: clean | default, default with impermanence, and custom (under `/persist/`) bundles fail no `services.lanzaboote` assertion |
| assertions: grub | forcing `boot.loader.grub.enable = true` fails exactly the grub assertion |
| control(grub) | grub is off in the clean enabled config |
| assertions: persist | a bundle outside `/persist/` with impermanence fails exactly the persist assertion and its message names the path |
| assertions: no impermanence | the same bundle without impermanence fails nothing |
| control(impermanence) | the stub option differs between those two twins |
| assertions: prefix trap | `/persistent/...` with impermanence fails the persist assertion |
| secureBoot: clean | `secureBoot` with `enable` and emergencyAccess off fails nothing |
| secureBoot: needs enable | `secureBoot` without `enable` fails exactly the enable assertion |
| secureBoot: emergencyAccess | `secureBoot` with `boot.initrd.systemd.emergencyAccess = true` fails exactly the emergencyAccess assertion |
| control(emergencyAccess) | the option flips between twins, and emergencyAccess alone (secureBoot false) fails nothing |
| control(secureBoot) | emergencyAccess without the module fails nothing; `secureBoot` without `enable` and with emergencyAccess fails only the enable assertion |
| control(checker) | the helpers reject wrong expectations (failure counts, a swapped conf) |

Realised file (build):

| Check | Expected |
|-------|----------|
| default bundle | line 1 is `%YAML 1.1`, line 2 is `---`, the rest is exactly the `guid` and `keydir` lines for the default bundle |
| custom bundle | the same for the custom bundle |
| control(file) | each file is rejected against the other bundle; a file with the header and a third key, a wrong `keydir` or a quoted value is rejected; a file without the header is rejected |
