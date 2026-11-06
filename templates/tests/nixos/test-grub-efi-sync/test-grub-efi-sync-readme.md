# test-grub-efi-sync

Verifies the `boot.loader.grub.extraInstallCommands` hook in `modules/nixos/toplevel/boot.nix` that keeps stale `EFI/NixOS*/grubx64.efi` copies identical to the freshly written `core.efi` (guards against GRUB `symbol '...' not found`, see Documentation/troubleshooting/README.md section 6).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-grub-efi-sync` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-grub-efi-sync/check-nixos-grub-efi-sync.sh
```

Or from inside the directory:

```bash
bash check-nixos-grub-efi-sync.sh
```

## How it works

The hook only exists while GRUB is the bootloader: `boot.nix` skips the whole GRUB block when `myconfig.services.lanzaboote.enable` is on (lanzaboote replaces the install hook). The scenario exposes `mode-<host>` (`grub` or `lanzaboote`, from that flag) and the script runs the hook checks only for `grub` hosts. A `lanzaboote` host instead gets one positive check: `boot.loader.grub.enable` is false and `extraInstallCommands` is empty. Which mode a host is in is not asserted.

`01-scenario-grub-efi-sync.nix` reads the real `nixosConfigurations.nixos-desktop` and `nixos-laptop` from the flake (only the grub options are forced, no build) and exposes the hook text (`script-<host>`) plus static checks as `"ok"` / `"FAIL: ..."`.

`check-nixos-grub-efi-sync.sh` runs the static checks, then writes the evaluated hook to a temp file, strips the store prefixes of `cmp`/`cp` (resolved from `PATH`), rewrites `/boot/` to a sandbox directory and runs it against synthetic EFI trees. A final control run sabotages the hook (`cp` becomes `true`) and expects the stale copy to remain, proving the replacement check can fail. The read-only case is skipped when running as root.

## Checks

### Mode (per host)
| Check | Expected |
|-------|----------|
| `mode-<host>` | evaluates to `grub` or `lanzaboote` |
| lanzaboote host: no hook | `boot.loader.grub.enable` false and `extraInstallCommands` empty |
| control: no-hook rule | the rule accepts only grub off with an empty hook (grub on or a non-empty hook is rejected) |

### Static (per grub host)
| Check | Expected |
|-------|----------|
| script non-empty | true |
| reads `/boot/grub/x86_64-efi/core.efi` | present |
| targets `/boot/EFI/NixOS*/grubx64.efi` | present |
| no `set -e`, no `exit N` | absent |
| `efiSupport` and `efiInstallAsRemovable` | both true (hook premise) |
| `bash -n` | parses |
| sandbox rewrite | all `/boot` refs rewritten, no unexpected store paths |

### Runtime (per grub host, sandboxed)
| Scenario | Expected |
|----------|----------|
| stale target | replaced by core.efi content, "refreshed" message, exit 0 |
| identical target | silent, exit 0 |
| several `NixOS*` dirs plus `EFI/BOOT` | all `NixOS*` refreshed, `EFI/BOOT` untouched |
| no `core.efi` | exit 0, target unchanged |
| no `NixOS*` dir | exit 0, nothing created |
| read-only target (non-root) | exit 0, WARNING on stderr, target unchanged |
| control: sabotaged hook | stale copy stays |
