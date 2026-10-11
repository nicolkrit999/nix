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

`01-scenario-grub-efi-sync.nix` reads the real `nixosConfigurations.nixos-desktop` and `nixos-laptop` from the flake (only the grub options are forced, no build) and exposes the hook text (`script-<host>`) plus static checks as `"ok"` / `"FAIL: ..."`.

`check-nixos-grub-efi-sync.sh` runs the static checks, then writes the evaluated hook to a temp file, strips the store prefixes of `cmp`/`cp` (resolved from `PATH`), rewrites `/boot/` to a sandbox directory and runs it against synthetic EFI trees. A final control run sabotages the hook (`cp` becomes `true`) and expects the stale copy to remain, proving the replacement check can fail. The read-only case is skipped when running as root.

## Checks

### Static (per host)
| Check | Expected |
|-------|----------|
| script non-empty | true |
| reads `/boot/grub/x86_64-efi/core.efi` | present |
| targets `/boot/EFI/NixOS*/grubx64.efi` | present |
| no `set -e`, no `exit N` | absent |
| `efiSupport` and `efiInstallAsRemovable` | both true (hook premise) |
| `bash -n` | parses |
| sandbox rewrite | all `/boot` refs rewritten, no unexpected store paths |

### Runtime (per host, sandboxed)
| Scenario | Expected |
|----------|----------|
| stale target | replaced by core.efi content, "refreshed" message, exit 0 |
| identical target | silent, exit 0 |
| several `NixOS*` dirs plus `EFI/BOOT` | all `NixOS*` refreshed, `EFI/BOOT` untouched |
| no `core.efi` | exit 0, target unchanged |
| no `NixOS*` dir | exit 0, nothing created |
| read-only target (non-root) | exit 0, WARNING on stderr, target unchanged |
| control: sabotaged hook | stale copy stays |
