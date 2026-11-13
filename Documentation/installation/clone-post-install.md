# Clone install: post-install checklist

For after [the clone installer](./clone-install.md) has finished. The installer prints a short version of this list at the end. Replace `<host>` with `nixos-desktop` or `nixos-laptop`; the installed machine is `<host>-2`.

## 1. First boot

1. Reboot, remove the USB stick and open the firmware setup.
2. Check the boot order: the entry `NixOS (<host>-2)` should be first. The installer only reorders; the `Windows Boot Manager` entry is untouched and still in the boot menu (or use `reboot-to-windows` from NixOS).
3. Laptop: the first boot asks for the LUKS passphrase you chose during the install.
4. Log in. Make sure nothing failed to start: `systemctl --failed`.

## 2. Secure Boot

The installer created fresh keys on this machine (the original's sbctl keys are never copied).

| Installer said | Do |
|---|---|
| keys enrolled (firmware was in Setup Mode) | turn Secure Boot **ON** in the firmware, nothing else |
| keys created but **not** enrolled (gate answered `c`) | in the firmware delete the Secure Boot keys to enter Setup Mode, boot `<host>-2`, run `sudo sbctl enroll-keys --microsoft`, then turn Secure Boot ON |

Verify after turning it on:

```bash
bootctl status | grep -i "secure boot"     # enabled (user) or enabled (deployed)
sudo sbctl status                          # Setup Mode: Disabled
sudo sbctl list-enrolled-keys              # your keys plus Microsoft
sudo sbctl verify                          # boot files signed
```

Some firmware restores factory keys when toggling Custom Mode: re-check `list-enrolled-keys` after the toggle. Boot Windows once to confirm it still starts; if anything refuses to boot, switch Secure Boot off in the firmware to get back. Background and recovery: [lanzaboote usage](../usage/secure-boot/lanzaboote.md), phases 2 and 3 of [lanzaboote](./lanzaboote.md).

## 3. TPM auto-unlock (laptop only)

Only after Secure Boot is **ON** (the TPM binds to PCR 7, the Secure Boot state, so sealing earlier is wasted). The desktop has no LUKS, so it has no TPM step.

```bash
tpm-reenroll        # shell helper: re-seals every crypt device to PCR 7
```

Reboot: no passphrase prompt means it worked. Details and the manual `systemd-cryptenroll` / `cryptsetup token export` verification are in phase 3, step 4 of [lanzaboote](./lanzaboote.md). Also back up the LUKS header off the disk, as described there.

## 4. Tailscale

```bash
tailscale status        # this machine appears as <host>-2
```

The node identity was carried over from the live system, so no new login is needed. If `<host>-2` is missing, the key was skipped or failed during the install: run `sudo tailscale up --hostname=<host>-2` (or provide a fresh auth key) after the first boot. The Attic cache and the NAS depend on this.

### The sops `tailscale_key` is not relied on

This is deliberate. Tailscale auth keys expire after 90 days at most, and a clone install happens every 2 to 3 years or after a dead machine, so any key stored in sops is expired when it is needed. The installer's fresh-key prompt (reusable on, ephemeral off, 1-day expiry, created right before the install) is the only supported path. **Do not try to "fix" or periodically replace the sops key**; an expired `tailscale_key` is the normal state, not a defect. The installer still tries it first because that costs nothing.

The same key is also wired as `services.tailscale.authKeyFile` on the installed hosts, but it only matters while the node has no valid identity. A host that keeps its `/persist/var/lib/tailscale` state (including a clone, which receives the live system's state from the installer) never needs it. If a machine ever loses that state, re-join it by hand with a fresh key: `sudo tailscale up --hostname=<name> --auth-key=<tskey-auth-...>` (do not store that key anywhere).

## 5. Settings inherited from the original (fix on new hardware)

The clone is the original's config. Disk and boot hardware were replaced by the generic layer; everything else is inherited as is, which may not match the new machine:

| Item | What to check |
|---|---|
| Monitors | connector names, resolutions, positions and per-monitor wallpapers/workspaces in `hosts/<host>/` and the compositor settings; fix them in the host config |
| GPU settings | GPU-specific kernel parameters, video/driver options and environment variables in `hosts/<host>/`; adjust or remove for a different GPU |
| Windows volume mount | the `windows-mount` service points to the original's Windows partition by UUID. It is `nofail`, so a wrong UUID only means `/mnt/windows` is not mounted. Set the new Windows volume UUID (`lsblk -f`) or disable it |
| Other by-UUID or by-path references | grep the host directory for `by-uuid`, `by-path` and device names (printers, extra disks, NAS mounts) |
| Hardware quirks | per-host workarounds written for the original's hardware (firmware patches, EC quirks, camera, audio) may not apply or may misbehave |

Because the clone shares `hosts/<host>/` with the original, a fix there also changes the original. Make such edits when the original is gone or knowingly shared; after [promotion](./clone-retire-and-promote.md) the host files belong to the new machine alone.

## 6. The repository

The installer leaves the repository at `~/nix`, `origin` set to `https://github.com/nicolkrit999/nix.git`.

```bash
git -C ~/nix rev-parse --is-shallow-repository    # false when the full history arrived
git -C ~/nix fetch --unshallow                     # only if it says true (the installer only warned)
git -C ~/nix status
```

Pushing needs your own credentials (SSH remote or token); set them up the way you do on the original.

## 7. Rebuild from the clone

```bash
cd ~/nix
nh os switch .
```

`nh` builds `nixosConfigurations.<networking.hostName>`, which is `<host>-2` here; the matching home-manager configuration is `krit@<host>-2`. The first switch builds whatever Attic or the public caches lack. Pull the latest `main` first.

## 8. Backups and other per-host services

- Borg: the repository folder follows `networking.hostName`, so this machine backs up to its own `<host>-2` folder on the NAS and never writes into the original's. Check the first backup run in the journal.
- Anything else that is named after the host (tailnet DNS names, NAS exports, scripts on other machines) refers to the original's name; `<host>-2` is a new name.

## 9. When the old machine goes away

Continue with [retire and promote](./clone-retire-and-promote.md). Until you promote, the clone is `<host>-2` permanently and the installer refuses a same-name install.
