# Why school-onedrive is NOT sops-managed

`school-onedrive` (SUPSI OneDrive Business, mounted via a systemd unit in
`users/krit/nixos/specializations/school.nix`) is **intentionally** not
sops-managed, unlike the personal cloud remotes (`pcloud.nix`,
`onedrive-personal.nix`, `google-drive.nix` under
`users/krit/nixos/services/cloud/`), which each have a
`sops.secrets.rclone_<provider>_conf` entry and pass `configFile` into
`myconfig.services.rcloneMount.mounts`.

School's `rclone mount school-onedrive: ...` line instead assumes a
`[school-onedrive]` section already exists in the ambient, unmanaged
`~/.config/rclone/rclone.conf` - nothing in the repo creates or restores it.

**Do not flag this as a gap/oversight.** SUPSI's OneDrive Business login goes
through institutional SSO with policies outside Krit's control (forced
password rotations, conditional access, MFA re-prompts). The refresh token
can be invalidated server-side far more often than a personal-account OAuth
token, forcing recurring interactive re-auth regardless of sops. Re-encrypting
the sops secret on every break (rerun `rclone config` → grab new conf →
sops-encrypt → commit → rebuild) is *more* steps than just re-running
`rclone config` locally - so sops would add overhead without solving the
actual problem. Same shape of tradeoff as the iCloud rclone remote (30-day
`trust_token` forcing recurring re-auth): when recurring interactive auth is
unavoidable, automating the storage isn't worth it.

If ever revisited, the fix would mirror `pcloud.nix`'s pattern
(`sops.secrets.rclone_school_onedrive_conf` + `configFile` in
`rcloneMount.mounts`) - but only worth it if SUPSI's auth model turns out to
be less volatile than assumed.
