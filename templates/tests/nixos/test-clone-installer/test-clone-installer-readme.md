# test-clone-installer

Lean CI test for the clone installer (`templates/installer/`, flake outputs `installer`, `make-bundle`, `installer-iso`, hosts `nixos-desktop-2` / `nixos-laptop-2`). A clone is the original host's whole config on new hardware: the same secrets, the same `stateVersion`s, the same `myconfig.constants.hostname` (kernel, dotfiles and sops key on it), only `networking.hostName` and the hardware layer differ. The installer then partitions a real disk next to a real Windows. None of that can be tried on the real machines, so the parts that decide it are proven here without touching a device: the clone invariants, where the installer outputs are (and are not) exposed, and the disk logic on sparse image files.

The full installer harness (`templates/installer/test-harness.sh`, about 200 assertions, about 3.5 min, fakes for every mutating tool) stays local-only; this test is its cheap subset.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-clone-installer` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-clone-installer/check-nixos-clone-installer.sh
```

Or from inside the directory:

```bash
bash check-nixos-clone-installer.sh
```

About 16 s warm (one scenario eval of four real hosts plus twelve mutant twins, one small tool fetch, sparse-image work).

## How it works

`check-nixos-clone-installer.sh` first realises `gptfdisk`, `jq` and `util-linux` from the flake's pinned nixpkgs (`nix build --inputs-from`, a few MB from the binary cache) and puts them first on `PATH`, so the result does not depend on what the machine has. It then runs three parts.

1. **Scenario eval** (`01-scenario-clone-installer.nix`): one `nix eval --json --impure` that loads the real flake and returns one `"ok"` / `"FAIL: ..."` string per check. `problems original clone expectedName` lists the invariants a clone breaks. The pairs (`nixos-desktop` / `nixos-desktop-2`, `nixos-laptop` / `nixos-laptop-2`) are the contract of the installer, not a host choice. The label-layer expectations are read from `templates/installer/layout.nix` (the same file the installer and `generic-hardware.nix` use), never typed again; the LUKS expectation follows the original (laptop yes, desktop no). Secrets are compared with each other (the clone's sops file, key paths and secret names against the original's), nothing is hardcoded.
2. **Layout contract**: the installer scripts and nix files are grepped for the layout values (ESP label, LUKS partlabel, mapper name, the four subvolume names, loaded through `dp_layout_load`); comment lines are skipped.
3. **Disk logic**: `templates/installer/disk-plan.sh` is sourced with `INSTALLER_TEST=1` (regular files only; the library itself refuses block devices in that mode) and run against sparse images (200 GiB Windows-style disk, full disk, ~58 GiB-free disk, empty, Ubuntu, bare ESP, a disk with two gaps) created with `sgdisk` under `${XDG_CACHE_HOME:-~/.cache}` (on disk, not the `/tmp` tmpfs; removed on exit). Only `sgdisk`, `sfdisk`, `blkid` and `jq` are used; no loop device, no mount, no `mkfs`, no `/dev`.

Every check can fail:

- Each clone invariant has a mutant twin (`extendModules` with `mkOverride 10`) that breaks exactly that property, and the same `problems` function must report it. The unmodified original passed off as its own clone must be reported for the hostname, label-layer, no-uuid and luks-device invariants (the original is by-uuid on both hosts).
- The output-shape predicates (`installerNameLike`, `exposesIso`, `onlyInstallerSystem`, `isApp`) are run on synthetic inputs that must be accepted and rejected (an ISO system built with a minimal `nixosSystem`, a darwin system key, a non-app).
- Layout guard: a throwaway script hardcoding the ESP label must be flagged, a comment line must not.
- Disk logic: each refusal has an accepted twin; the "Windows partitions untouched" check has a control that renames the Windows ESP and must see the difference.
- `CLONE_INSTALLER_DIR` points the bash half at a copy of `templates/installer/` so a mutated `disk-plan.sh` can be run through the same checks (used to prove them; not needed in normal runs).

A failing check is not proof of a config bug: diagnose before touching the test.

## Checks

### Clone hosts (scenario eval, per pair: `clone-desktop-*` and `clone-laptop-*`)

| Check | Expected |
|-------|----------|
| `clone-<pair>-exists` | the original and its `-2` clone are both in `nixosConfigurations` |
| `clone-<pair>-hostname` | the clone's `networking.hostName` is its own `-2` name and differs from the original's |
| `clone-<pair>-constants-hostname` | `myconfig.constants.hostname` equals the original's |
| `clone-<pair>-constants` | all `myconfig.constants` serialise identically to the original's |
| `clone-<pair>-system-stateversion` | `system.stateVersion` equals the original's |
| `clone-<pair>-home-stateversion` | `myconfig.constants.homeStateVersion` equals the original's |
| `clone-<pair>-sops-file` | `sops.defaultSopsFile` is the original's file |
| `clone-<pair>-sops-keys` | `sops.age.sshKeyPaths` equals the original's |
| `clone-<pair>-sops-secrets` | the set of `sops.secrets` names equals the original's |
| `clone-<pair>-bootloader` | `boot.lanzaboote.enable`, `boot.loader.grub.enable` and `canTouchEfiVariables` equal the original's |
| `clone-<pair>-persist-flags` | `neededForBoot` of `/persist` and `/var/log` equals the original's |
| `clone-<pair>-label-layer` | `/boot` is `by-label/<espLabel>`; `/persist`, `/nix`, `/home`, `/var/log` are `by-label/<btrfsLabel>` (no LUKS) or `/dev/mapper/<luksMapperName>` (LUKS original), all values from `layout.nix` |
| `clone-<pair>-no-uuid` | none of those five mounts uses `by-uuid` |
| `clone-<pair>-luks-device` | LUKS original: the clone's mapper device is `by-partlabel/<luksPartLabel>`; non-LUKS original: the clone has no LUKS device |

### Controls (scenario eval)

| Check | Expected |
|-------|----------|
| `control-original-as-clone-desktop` / `-laptop` | the unmodified original is reported as a bad clone (hostname, no-uuid, plus label-layer on the desktop and luks-device on the laptop) |
| `control-mutant-hostname-unchanged` | a clone that keeps the original hostName is reported (`hostname`) |
| `control-mutant-constants-hostname` | a changed `constants.hostname` is reported |
| `control-mutant-system-stateversion` | a bumped `system.stateVersion` is reported |
| `control-mutant-home-stateversion` | a bumped `homeStateVersion` is reported |
| `control-mutant-sops-file` | another host's sops file is reported |
| `control-mutant-sops-keys` | another key path is reported |
| `control-mutant-sops-secrets` | an extra secret is reported |
| `control-mutant-bootloader` | a flipped `canTouchEfiVariables` is reported |
| `control-mutant-persist-flags` | `/persist` without `neededForBoot` is reported |
| `control-mutant-uuid-boot` | `/boot` by-uuid is reported (`no-uuid`) |
| `control-mutant-label-layer` | `/boot` on a foreign label is reported |
| `control-mutant-luks-device` | a by-uuid LUKS device on the laptop clone is reported |
| `control-name-predicate-catches-iso` | `installer-iso` / `clone-iso` match the installer-name predicate, `nixos-desktop-2` does not |
| `control-isoimage-predicate-catches-iso` | an ISO system exposes `system.build.isoImage`, a real host does not |
| `control-system-predicate-catches-darwin` | an extra darwin system key or an empty set is rejected, `x86_64-linux` alone accepted |
| `control-app-predicate` | an app is accepted; a derivation and an empty set are not |

### Installer outputs (scenario eval)

| Check | Expected |
|-------|----------|
| `outputs-packages-x86_64-linux` | `packages.x86_64-linux` holds `installer`, `make-bundle` and `installer-iso` as derivations |
| `outputs-apps-x86_64-linux` | `apps.x86_64-linux` holds `install` and `make-bundle` as `app`s with a program path |
| `outputs-iso-not-a-nixos-configuration` | no `nixosConfigurations` entry is named like the installer/ISO and none exposes `system.build.isoImage` |
| `outputs-iso-not-a-home-or-darwin-config` | no `homeConfigurations` / `darwinConfigurations` entry is named like the installer/ISO and the clone hosts are not in `darwinConfigurations` |
| `outputs-installer-linux-x86_64-only` | `packages` and `apps` have exactly one system, `x86_64-linux` |

### Layout contract

| Check | Expected |
|-------|----------|
| layout.nix loads through dp_layout_load | all layout values are read |
| no layout value hardcoded in the installer scripts or nix files | no non-comment line of `disk-plan.sh`, `install.sh`, `make-bundle.sh`, `packages.nix`, `iso.nix`, `hardware-select.nix`, `generic-hardware.nix` contains an ESP label, LUKS partlabel, mapper name or subvolume name |
| control: a script that hardcodes the ESP label is flagged | the scan finds the throwaway script |
| control: a comment line is not flagged | the scan ignores comments |
| generic-hardware.nix imports layout.nix | the hardware layer reads the shared contract |

### Disk logic on sparse images

| Check | Expected |
|-------|----------|
| classify: Windows disk | `windows` |
| classify: full Windows disk | `windows` |
| classify: Ubuntu disk | `other-os` |
| classify: empty file | `empty` |
| classify: bare ESP with room | `free-space` |
| classify: bare ESP without room | `unknown` |
| control: Windows and Ubuntu disks are told apart | the two classes differ |
| wipe: Windows disk refused without the ack | rc 1, reason names `no Windows, wipe` |
| wipe: Ubuntu disk refused without the ack | rc 1 |
| control: Windows disk wipe allowed with the ack | rc 0 |
| wipe: empty disk allowed | rc 0 |
| wipe: in-use disk refused even with the ack | rc 1 |
| free-space: Windows disk with room accepted | rc 0 |
| free-space: full Windows disk refused | rc 1, reason says to shrink in Windows |
| free-space: Windows disk below the minimum refused | rc 1 |
| free-space: Ubuntu disk refused (no Windows ESP) | rc 1 |
| free-space: empty disk refused (nothing to sit next to) | rc 1 |
| free block: Windows disk, 1 MiB aligned start | start sector divisible by 2048 |
| free block: Windows disk leaves ~98 GiB | between 97 and 99 GiB |
| free block: empty disk is (almost) the whole disk | more than 199 of 200 GiB |
| free block: the largest gap wins, not the first | more than 250 GiB on the two-gap disk |
| free block: starts at or after the last partition | the chosen block begins behind the last partition |
| plan: free-space + LUKS accepted | rc 0; new ESP is partition 5, root 6, root type 8309 |
| apply_partition --dry-run changes nothing | partition table unchanged |
| apply_partition (free-space, LUKS) | rc 0 |
| Windows partitions 1-4 (incl. the Windows ESP) identical after apply | start, size, type, GUID and name unchanged |
| Windows ESP (partition 1) identical after apply | same, for the Windows ESP alone |
| new ESP: EFI type, label from layout.nix | partition 5 has the EFI type GUID and `espLabel` |
| new root: LUKS type, partlabel from layout.nix | partition 6 has the LUKS type GUID and `luksPartLabel` |
| new ESP is 4 GiB | 4 GiB in sectors |
| control: renaming the Windows ESP would be seen by the identity check | the identity listing differs after `sgdisk -c 1:renamed` |
| plan: free-space on a full disk fails | rc 1 |
| plan: free-space on an in-use disk fails | rc 1 |
| refusals leave the original Windows image untouched | `sfdisk -d` plus mtime unchanged |
