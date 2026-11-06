# test-reboot-to-windows

Pins the behaviour of the `reboot-to-windows` command that `services.lanzaboote` installs (`pkgs.writeShellApplication` in `modules/nixos/services/lanzaboote.nix`): it reads `efibootmgr -v`, finds the Windows Boot Manager entry, sets `BootNext` to it and reboots. A wrong match or a missing guard reboots into the wrong system or reboots with no `BootNext` set, and it is only noticed at the next dual-boot.

Why it exists:

- **Right entry.** Only real `BootXXXX` entry lines count, matched case-insensitively by the label `Windows Boot Manager` or by the loader path `\EFI\Microsoft\Boot\bootmgfw.efi` (either slash direction), so a renamed entry is still found. The `BootCurrent`, `BootNext` and `BootOrder` header lines never match, even when they mention Windows.
- **Nothing happens without a match.** No entry means `no Windows boot entry found` on stderr, exit 1, and neither `--bootnext`, a reboot nor sudo is called.
- **Several matches.** The first one in listing order is used and a warning lists all ids.
- **Root handling.** A non-root caller is re-executed through sudo with the script path and its arguments (and sudo's exit status becomes the script's); a root caller never calls sudo.
- **No half-done reboot.** A failing `efibootmgr -v` or a failing `--bootnext` stops the script before `systemctl reboot` (`errexit`).

The three commands the script calls are replaceable through the hooks `REBOOT_TO_WINDOWS_EFIBOOTMGR`, `REBOOT_TO_WINDOWS_SYSTEMCTL` and `REBOOT_TO_WINDOWS_SUDO`; the test points them at logging shims, so nothing touches real firmware, systemd or sudo.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-reboot-to-windows     # from the repo root
bash check-nixos-reboot-to-windows.sh                                # from this folder
```

Expected result: PASS. One fixture host evaluation and one tiny build (the script itself, `shellcheck` runs in its build); the shim runs take about a second.

## How it works

1. `01-scenario-reboot-to-windows.nix` builds a fixture host from scratch (`shared/`: a bare host with `constants.user`, the platform and a home-manager base; only the lanzaboote module is loaded, no GRUB or impermanence module). `checks` proves the package is absent with the module off and present exactly once with it on; `script` is that package, found by name in `environment.systemPackages` (no real host is read).
2. `check-nixos-reboot-to-windows.sh` builds `script` and runs `bin/reboot-to-windows` per case with the three hooks pointing at shims in a temp dir. The `efibootmgr` shim prints a synthetic `efibootmgr -v` listing (fake GUIDs) and logs its arguments, the `systemctl` and `sudo` shims only log (sudo's log is `script|arg|arg`). Failure exits are injected through `SHIM_V_RC`, `SHIM_NEXT_RC` and `SHIM_SUDO_RC`.
3. The script reads root-ness with `id -u` and prefixes its own `PATH` with the coreutils store path, so a `PATH` shim of `id` would be shadowed. The runner instead exports a bash function `id` (`export -f`) that prints the fake uid: functions win over `PATH`, the script is a bash script, and the result no longer depends on who runs the test (uid 0 or 1000).
4. Controls: the whole case suite runs again on an unmodified copy of the script (must be all green) and on ten mutated copies, each made by replacing one literal fragment of the script text (the replacement must apply and change the file). Each mutant must trip the named checks, so a check that cannot fail is caught.

Fake data only: no key, fingerprint or token exists in the test, the partition GUID is a made-up constant.

## Checks

Eval checks (fixture host):

| Check | Expected |
|-------|----------|
| module off: reboot-to-windows is not installed | no `reboot-to-windows` in `environment.systemPackages` |
| module on: reboot-to-windows is installed exactly once | exactly one package named `reboot-to-windows` |

Script checks (built script, shims; "root" means fake uid 0, "non-root" fake uid 1000):

| Check | Expected |
|-------|----------|
| binary exists and is executable | `bin/reboot-to-windows` of the built package |
| root, one Windows entry: stdout, exit, stderr | stdout exactly `rebooting into Windows via Boot0000`, exit 0, empty stderr |
| root, one Windows entry: calls | efibootmgr gets `-v` then `--bootnext 0000`, systemctl gets `reboot` |
| root: sudo is not called | empty sudo log |
| root, no Windows entry: message | stderr exactly `no Windows boot entry found`, exit 1, empty stdout |
| root, no Windows entry: calls | only `-v`; no `--bootnext`, no reboot |
| non-root, no Windows entry | exit 1, no sudo call, no reboot (the match runs before the root check) |
| root, two entries | stderr exactly `several Windows boot entries (0000 0007), using the first`; `Boot0000` used |
| root, two entries: calls | `--bootnext 0000` and one reboot |
| root, two entries, 0007 listed first | stderr `(0007 0000)`, `--bootnext 0007` (listing order, not numeric order) |
| renamed label, upper-case backslash path | `Boot000a` with `\EFI\MICROSOFT\Boot\BootMgFw.EFI` matched, `--bootnext 000a` |
| inactive entry, upper-case id, forward slashes | `Boot00B1` (no `*`) with `/EFI/Microsoft/Boot/bootmgfw.efi` matched, `--bootnext 00B1` |
| lower-case label | `windows boot manager` on an unrelated path matched, `--bootnext 0003` |
| BootCurrent/BootNext/BootOrder naming Windows | with only Linux entries: exit 1, `no Windows boot entry found`, no `--bootnext` |
| same lines plus one real entry | exactly one match: empty stderr (no `several` warning), `--bootnext 0000` |
| non-root, Windows entry: sudo re-exec | sudo log is exactly `<script path>\|a\|b c` for the arguments `a` and `b c`; no `--bootnext`, no reboot, empty stdout |
| non-root: sudo exit status | sudo shim exiting 7 gives script exit 7 |
| `efibootmgr -v` failing | non-zero exit, only `-v` logged, no reboot, no sudo |
| `--bootnext` failing | non-zero exit, no reboot |

Controls (mutated copies of the script; each row must make the listed checks fail):

| Control | Mutation | Checks that must fail |
|---------|----------|-----------------------|
| unmodified copy | none | none (all checks pass) |
| case-sensitive grep | `grep -iE` to `grep -E` | the three mixed-case entry checks |
| loose Boot anchor | `^Boot[0-9a-f]{4}\*? .*` to `^Boot.*` | both BootCurrent-trap checks |
| no root gate | root check replaced by `:` | sudo re-exec, sudo exit status |
| root gate before matching | root check inserted before the no-match exit | non-root, no Windows entry |
| last match used | `head -n1` to `tail -n1` | both first-match checks |
| silent multi-match | the `several` warning turned into a no-op | both first-match checks |
| no bootnext | `--bootnext` call replaced by `:` | one-entry calls, two-entry calls, renamed path |
| no reboot | `systemctl reboot` replaced by `:` | one-entry calls, two-entry calls |
| no-match exits 0 | `exit 1` to `exit 0` | no-entry message |
| errexit off | `set -o errexit` to `set +o errexit` | `--bootnext` failing |
