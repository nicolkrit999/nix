# test-nas-mounts

Eval-only guard for the NAS (cifs, sshfs, davfs), windows-partition and rclone cloud mount definitions on the real `nixos-desktop` and `nixos-laptop` configs.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-nas-mounts` (name as shown by `--list`); the direct command is below.

From the repo root:

```bash
bash templates/tests/nixos/test-nas-mounts/check-nixos-nas-mounts.sh
```

From inside the directory:

```bash
bash check-nixos-nas-mounts.sh
```

Eval only. Two host evaluations, each with a few `extendModules` controls; 115 s inside the full parallel suite run of 2026-10-11. Runs in the `nixos-b` CI group (`test.conf`).

## How it works

`01-scenario-nas-mounts.nix` reads `HOST_UNDER_TEST`, loads the real flake and exposes one string per check (`"ok"` or `"FAIL: ..."`). `check-nixos-nas-mounts.sh` runs `nix eval --json --impure` once per host, prints a per-check PASS/FAIL list and exits non-zero on any failure.

Values are compared against independent sources (sops secret paths, `users.users`, the enabled cloud modules, the opencloud `spaces` list) so no secret or address is hardcoded. Controls: sshfs is disabled on both hosts, so it is checked both disabled (no mount) and enabled via `extendModules`; the windows-mount assertion is proven to fire on an unmapped hostname via `extendModules`. The `$PATH` sweep covers every home-manager user unit of the base system and of every specialisation, plus system units.

## Checks

### cifs (smb)

| Check | Expected |
|-------|----------|
| smb-mounts-under-user-dir | at least one cifs mount, all under `/mnt/nicol_nas/smb/<user>/` (the exact count is a host choice and not asserted) |
| smb-single-nas-host / share-names-nonempty | one device host, every device has a non-empty share |
| smb-local-names-unique | local names unique, non-empty, no spaces |
| smb-credentials | `credentials=` equals the `nas-krit-credentials` sops path, non-empty |
| smb-vers, smb-automount | `vers=3.1.1`, `noauto`, `x-systemd.automount`, `_netdev`, `nofail` |
| smb-uid-gid | `uid=` equals `constants.user` (the name) and `gid=` equals `users.users.<user>.group` (the group name, not a numeric gid) |
| smb-fsc-needs-cachefilesd / fsc-used | `fsc` implies cachefilesd enabled; guard that `fsc` is actually used |
| nas-root-tmpfiles / no-looser-rule | `/mnt/nicol_nas` is 0700 owned by the user, no rule with another mode |

### sshfs, davfs

| Check | Expected |
|-------|----------|
| sshfs-disabled-no-mount | sshfs mount exists only if sshfs is enabled (whether a host enables it is not asserted) |
| sshfs-when-enabled / identity / same-host-as-smb | `fuse.sshfs`, automount, `IdentityFile=` is the `nas_ssh_key` sops path, same host as smb |
| davfs-count-matches-spaces / paths / automount / device-urls | one davfs mount per space under `/mnt/nicol_nas/webdav/opencloud/`, `noauto` + automount, https devices |
| davfs-secrets-wired / university-0700 | `/etc/davfs2/secrets` sourced from the configured file; University dir 0700 |

### uid pin

| Check | Expected |
|-------|----------|
| user-uid-pinned | `users.users.<user>.uid` is 1000 on both hosts |
| sshfs-uid-gid | sshfs `uid=`/`gid=` equal the configured uid and the primary group's gid (not literals) |
| windows-uid-gid | ntfs3 `uid=`/`gid=` equal the configured uid and the primary group's gid |
| davfs-uid-gid | davfs `uid=` is the `constants.user` name (cifs is covered by smb-uid-gid) |

### windows

| Check | Expected |
|-------|----------|
| windows-uuid | `/mnt/windows` device is the mapped by-uuid path for the host, ntfs3 |
| windows-assertion-passes | no failing windows-mount assertion on the real host |
| windows-assertion-fires-on-unknown-host | assertion fires for an unmapped hostname |

### rclone

| Check | Expected |
|-------|----------|
| rclone-enabled-matches-cloud-modules | mount count equals enabled `krit.services.cloud.*` modules |
| rclone-names-unique / fields-nonempty / mountpoints-unique | unique non-empty names, non-empty fields, unique mount points not clashing with fileSystems |
| rclone-units-exist / execstart / execstop / tmpfiles | HM unit per mount; ExecStart has config, remote and mount point; ExecStop unmounts; tmpfiles rule |
| rclone-sops-secret-declared / sops-file-has-key | configFile is a declared `rclone_*` secret owned by the user; its sopsFile exists and contains the key |
| no-literal-PATH-in-hm-units / system-units | no `Environment` entry contains a literal `$PATH` (base and every specialisation) |
| sweep-covers-school-unit | the sweep sees `school-onedrive-mount` in the school specialisation |

No synthetic hosts are built beyond two minimal `extendModules` overrides (sshfs enabled, unmapped hostname); everything else evaluates the real hosts.
