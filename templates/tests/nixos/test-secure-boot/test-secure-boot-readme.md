# test-secure-boot

Pins the contract of the generic `services.secure-boot` module (`modules/nixos/services/secure-boot.nix`, lanzaboote) on a fixture host built from scratch: the module under test, the constants schema and a stub `services.impermanence` option, nothing else.

Why it exists:

- **Keys must survive a reboot.** With impermanence the root is a tmpfs, so a `pkiBundle` outside `/persist/` loses the signing keys and the machine cannot sign new generations. The module asserts this, and the test proves the assertion fires only with impermanence on (including the `/persistent/...` prefix trap) and not otherwise.
- **One bootloader.** lanzaboote replaces the bootloader install hook; GRUB enabled next to it must fail an assertion, and `systemd-boot` must stay forced off.
- **Manual key handling.** Keys are created and enrolled by hand with `sbctl`: `autoGenerateKeys`, `autoEnrollKeys` and `measuredBoot` stay off, `sbctl` is installed, `/etc/sbctl/sbctl.conf` points `sbctl` at the same `pkiBundle` as lanzaboote (without it `sbctl` falls back to `/var/lib/sbctl`, which is tmpfs), and the directory is pre-created root-only.

The host side of the contract (which bootloader branch each real host satisfies, GRUB hook gating, the borgmatic exclusion of the key directory) lives in `nixos-host-invariants`, `nixos-grub-efi-sync` and `nixos-borg-backup-config`. Which host enables the module is deliberately not asserted anywhere.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-secure-boot     # from the repo root
bash check-nixos-secure-boot.sh                                # from this folder
```

Expected result: PASS. About 11 s of evaluation (fixture host plus ten `extendModules` twins) and one tiny build (the `remarshal` YAML generation of `sbctl.conf`, twice).

## How it works

1. `01-scenario-secure-boot.nix` builds the fixture host (`shared/host-secure-boot.nix`: only `constants.user`; `shared/impermanence-stub.nix` declares `myconfig.services.impermanence.enable`; `inputs` is passed through `specialArgs` so `inputs.lanzaboote` resolves). Twins set the module options, force `boot.loader.grub.enable`, turn the stub impermanence on, or define `boot.loader.systemd-boot.enable` / the lanzaboote key options directly. `checks` maps a name to `"ok"` or `"FAIL: ..."`; `bundles` exposes the two `pkiBundle` values; `etcSource.{default,custom}` are the `/etc/sbctl/sbctl.conf` derivations of the default and custom twins.
2. Assertions are read from `config.assertions`: only failing entries whose message contains `services.secure-boot` are counted, then split by the grub and persist message fragments.
3. `check-nixos-secure-boot.sh` prints the eval checks, builds both `sbctl.conf` derivations and compares the realised file with the expected two lines (`guid: <bundle>/GUID`, `keydir: <bundle>/keys`, quotes ignored, sorted). The `%YAML 1.1` directive and the `---` document start that `pkgs.formats.yaml` writes (lanzaboote's own `sbctl.conf` has the same header, and `sbctl` parses it) are dropped before the comparison; every other line must match. The eval checks also read the attrset the file is generated from (`source.value`), so the eval level and the realised file agree.

Fake data only: the bundle paths are made-up directories, no key or fingerprint exists anywhere in the test.

## Checks

Eval checks (fixture host and twins):

| Check | Expected |
|-------|----------|
| defaults: lanzaboote off | module off: `boot.lanzaboote.enable` false |
| defaults: nothing written | module off: no `sbctl/sbctl.conf` in `environment.etc`, no tmpfiles rule mentioning `sbctl`, no `sbctl` package |
| defaults: pkiBundle | `/persist/var/lib/sbctl` |
| defaults: configurationLimit | 10 |
| control(off) | the enabled twin does write sbctl.conf, a tmpfiles rule, the package and lanzaboote (the off result is not an unloaded module) |
| enabled: lanzaboote on | `boot.lanzaboote.enable` true |
| enabled: defaults propagate | `boot.lanzaboote.pkiBundle` and `configurationLimit` equal the module defaults (`/persist/var/lib/sbctl`, 10) |
| enabled: custom values propagate | a custom `pkiBundle` and `configurationLimit = 3` reach `boot.lanzaboote` |
| enabled: systemd-boot forced false | a plain `boot.loader.systemd-boot.enable = true` still evaluates to false |
| control(systemd-boot) | the same plain definition without the module stays true |
| enabled: sbctl package | `pkgs.sbctl` is in `environment.systemPackages` |
| enabled: tmpfiles rule | exactly `d <pkiBundle> 0700 root root -` for the default and the custom bundle |
| control(tmpfiles) | the custom twin carries only the custom rule, the default twin only the default rule |
| enabled: sbctl.conf attrs | exactly `keydir = <bundle>/keys` and `guid = <bundle>/GUID` for the default and the custom bundle (same bundle as lanzaboote) |
| control(sbctl.conf) | default and custom contents differ |
| enabled: key options off | `autoGenerateKeys`, `autoEnrollKeys`, `measuredBoot` false |
| control(keys) | a twin enabling the three options reads true for all |
| assertions: clean | default, default with impermanence, and custom (under `/persist/`) bundles fail no `services.secure-boot` assertion |
| assertions: grub | forcing `boot.loader.grub.enable = true` fails exactly the grub assertion |
| control(grub) | grub is off in the clean enabled config |
| assertions: persist | a bundle outside `/persist/` with impermanence fails exactly the persist assertion and its message names the path |
| assertions: no impermanence | the same bundle without impermanence fails nothing |
| control(impermanence) | the stub option differs between those two twins |
| assertions: prefix trap | `/persistent/...` with impermanence fails the persist assertion |
| control(checker) | the helpers reject wrong expectations (failure counts, a swapped conf) |

Realised file (build):

| Check | Expected |
|-------|----------|
| default bundle | apart from the `%YAML 1.1` / `---` header, `sbctl.conf` is exactly the `guid` and `keydir` lines for the default bundle |
| custom bundle | the same for the custom bundle |
| control(file) | each file is rejected against the other bundle; a file with the header and a third key is rejected; a file with the header and a wrong `keydir` is rejected |
