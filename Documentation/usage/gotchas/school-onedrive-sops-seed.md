# school-onedrive: sops-managed, mounted from a seeded writable copy

The SUPSI OneDrive Business remote (`school-onedrive`) is mounted at `~/oneDrive` of the `krit-school` user through `services.rcloneMount` (`users/krit/nixos/specializations/school.nix`). Its rclone config is the sops key `rclone_school_onedrive_conf` (`users/krit/common/sops/krit-common-secrets-sops.yaml`), the same pattern as the personal clouds under `users/krit/nixos/services/cloud/`.

## How it works

- sops-nix decrypts the key to a read-only file. rclone cannot persist a refreshed OAuth token there, so `rclone-mount-school-onedrive` (a user unit) mounts from a **writable copy**: before each start `rclone-seed-config` copies the sops file to `$XDG_STATE_HOME/rclone-mount/school-onedrive.conf` (for a user unit `%S`, so `~/.local/state/rclone-mount/school-onedrive.conf`), but **only if that copy does not exist**.
- Token refreshes are written into the copy and survive restarts and reboots.
- Consequence: re-encrypting the sops key changes nothing until the copy is deleted. The sops secret is only the seed.

## Why re-auth keeps happening

SUPSI's OneDrive Business login goes through institutional SSO with policies outside our control (forced password rotations, conditional access, MFA re-prompts). The refresh token can be invalidated server-side far more often than a personal-account token, so a recurring interactive re-auth is expected. sops does not change that; it only makes the seed reproducible and keeps the config out of the repo in plaintext.

## Re-auth recipe

1. Create the new config in a throwaway file, never in the ambient rclone config:
   `rclone config --config /dev/shm/school-onedrive.conf` (new remote named `school-onedrive`, type `onedrive`, SUPSI account, browser auth).
2. Store the whole file as the key `rclone_school_onedrive_conf`:
   `sops set users/krit/common/sops/krit-common-secrets-sops.yaml '["rclone_school_onedrive_conf"]' "$(jq -Rs . < /dev/shm/school-onedrive.conf)"`
3. `shred -u /dev/shm/school-onedrive.conf`.
4. Rebuild, boot the school specialisation and, as `krit-school`:
   `systemctl --user stop rclone-mount-school-onedrive; rm ~/.local/state/rclone-mount/school-onedrive.conf; systemctl --user start rclone-mount-school-onedrive`
   (the missing copy is reseeded from the new sops file).

## Build-time requirement

The key must exist in the yaml **at build time**: sops-nix checks the manifest during the build, so a missing key fails the build of the specialisation, not only its boot. See also `school-krit-school-user.md`.
