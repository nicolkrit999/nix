# Clone install: retire the old machine, promote the clone

For when a [clone](./clone-install.md) replaces an original PC. Two independent parts: [retiring or selling](#retire-or-sell-the-old-machine) the old hardware (do this once the clone is verified), and [promoting](#promote-the-clone-to-the-original-name) the clone so it carries the original's name.

> **Promotion is manual.** There is no promotion script yet, only the procedure below. Until a host is promoted, its installs are `<host>-2` only: the installer refuses a same-name install because the original config still points at the old machine's disks (by UUID).

## Retire or sell the old machine

Do this only after the clone has run for a while: Secure Boot on, TPM re-enrolled (laptop), a backup run succeeded, and you restored one file from the backup to prove it.

### Why the old disk must really be erased

The clone shares the original's SSH host key, which is a sops recipient for every secret in the repo, and the user age key. Both are on the old disk. The old disk also holds:

- the sbctl **private** Secure Boot keys (`/persist/var/lib/sbctl`),
- the Tailscale node identity and every token or password the system has ever decrypted,
- on the desktop **no LUKS**: everything is readable by anyone who plugs the disk in. The laptop is LUKS-encrypted, which helps, but the header and a TPM-bound key are still on the machine.

A simple delete or reinstall is not an erase. Treat the disk as holding the keys to your secrets.

### Checklist

1. **Stop the backups of the old machine** so it stops writing to its borg repository: disable the borg timers (or power the machine off for good). This must happen before you rename the repository folder when promoting.
2. **Secure-erase the disk(s)**, outside the running system (live USB):
   - Laptop (LUKS): first destroy the key material, `cryptsetup erase <luks-partition>` (removes all key slots), then do the secure erase below. The first step alone is not enough if you cannot trust the drive.
   - NVMe: `nvme format /dev/nvmeXn1 --ses=1` (user data erase) or `nvme sanitize` with a block erase or crypto erase action; check `nvme id-ctrl` for what the drive supports. SATA SSD: ATA Secure Erase (`hdparm --security-erase`) after setting a temporary password.
   - Do every disk that ever held data of this host (the desktop has several: Windows, Ubuntu, data disks), not only the NixOS one.
3. **Reset the firmware**: restore the factory Secure Boot keys (drop the custom PK/KEK/db), turn Secure Boot back to the default state, **clear the TPM**, remove any BIOS/admin password you set.
4. **Delete the old node from the tailnet** in the Tailscale admin console (Machines, the old host's name, Delete). This kills its node key immediately. Do it before promotion so the name is free.
5. **If you cannot trust the erase** (drive without working secure erase, damaged drive, drive sold unwiped, machine lost): assume the secrets are exposed. Rotating only the sops *recipient* (new host key, `sops updatekeys`) is **not enough**: the old key still decrypts old versions of the files in git history. Rotate the actual *values*: every token, password, auth key and API key stored in the host and common sops files (Tailscale and Attic tokens, Wi-Fi and account passwords, borg passphrase and NAS credentials, anything else in there), revoke the old ones at their services, then re-encrypt with new host and user keys and rebuild every machine.

## Promote the clone to the original name

Result: the machine installed as `<host>-2` becomes `<host>`; the `-2` entries disappear; the original's host files describe the new hardware layer. Preconditions: the old machine is retired (or you accept that it can no longer be rebuilt from `main`), and the clone is verified.

All edits are in your clone of the repo on the new machine, then pushed:

1. **Swap the hardware layer.** In `hosts/<host>/system.nix` replace the `hardware-select.nix` import

   ```nix
   (import ../../templates/installer/hardware-select.nix {
     original = ./hardware-configuration.nix;
     luks = <true|false>;   # unchanged: laptop true, desktop false
   })
   ```

   with the generic layer:

   ```nix
   (import ../../templates/installer/generic-hardware.nix { luks = <true|false>; })
   ```

   After this, `/boot` is the by-label device, which is exactly what the installer checks before it allows a same-name install. The old `hosts/<host>/hardware-configuration.nix` becomes unused (delete it when you no longer need it as a reference).
2. **Remove the `-2` entry.** In `flake.nix` delete the `"<host>-2" = "<host>";` line from `cloneHosts` (this drops both `nixosConfigurations.<host>-2` and `krit@<host>-2`).
3. **Update everything that names the pair.** The clone invariants test reads the pairs as the installer contract, and docs mention the `-2` hosts; grep the repo for `<host>-2`. Also remove the pair from other host-keyed lists you added by hand.
4. **Borg repository folder.** The folder follows `networking.hostName`, so after the rename the host writes to `borgitory/<host>` again. Either (a) move the old `borgitory/<host>` folder out of the way (archive or delete it, it belongs to the retired machine) and rename `borgitory/<host>-2` to `borgitory/<host>` to keep the clone's history, or (b) start a fresh repository under the original name. Do it with both backups stopped. Borg may ask once to confirm a relocated repository; check the first run in the journal.
5. **Tailnet node name.** The node is called `<host>-2`. After the old node is deleted (retire step 4), rename it to `<host>` in the admin console, and check `tailscale status` after the switch. Rename or fix anything on other machines that refers to `<host>-2`.
6. **Sops.** Nothing to rename: `myconfig.constants.hostname` already is the original's, so the per-host sops file path and the `.sops.yaml` rule for `<host>` are unchanged, and the clone has been using the original's host key from the start. Just confirm secrets still decrypt after the switch.
7. **Commit and verify.** Evaluate the host and run the checks before you switch, then switch under the new name:

   ```bash
   nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
   nix build .#nixosConfigurations.<host>.config.system.build.toplevel
   nh os switch . --hostname <host>
   ```

   Then run the flake check and the affected tests (flake outputs, the clone installer test, anything keyed on the pair), push, and confirm `hostname` and `tailscale status` show `<host>`.

From now on a new clone of this host is a same-name install (`same name (only after promotion)` in the installer); the installer's own `-2` option for it no longer exists.

## Known unverified items

Promotion has never been run end to end. In particular the borg relocation prompt, the Tailscale rename behavior with stored node state, and `nh os switch --hostname` across a hostname change are untested. The other unverified items of the installer are listed in [clone install](./clone-install.md#known-unverified-items).
