# Nicol-NAS bootstrap (out-of-band, non-Nix-managed)

UGREEN NAS running UGOS (Debian 12 bookworm base, x86_64). UGOS owns the OS -
this host is **home-manager-standalone only** (flake attr
`homeConfigurations."krit@Nicol-NAS"`). There is no `nixosConfigurations` entry
and no disko/system-level management here.

`/` is an overlayfs on `nvme2n1p7`. A UGOS firmware update can wipe the overlay
back to factory, which destroys everything documented below. `/volume2` (the
user NVMe pool) persists across firmware updates. This README exists so the
host can be re-provisioned quickly after a wipe - none of these steps are
captured in the flake.

Hostname: `Nicol-NAS`. User: `krit` (uid 1000).

## 1. Bind-mount `/nix` onto persistent storage

The actual store data lives on `/volume2/nix`, which survives a firmware wipe.
Only the systemd mount unit needs to be re-created after a wipe.

```bash
sudo mkdir -p /volume2/nix /nix
```

`/etc/systemd/system/nix.mount`:

```ini
[Unit]
Description=Bind mount /nix to /volume2/nix
RequiresMountsFor=/volume2
Before=nix-daemon.service

[Mount]
What=/volume2/nix
Where=/nix
Type=none
Options=bind

[Install]
WantedBy=local-fs.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nix.mount
```

## 2. Install Nix (Determinate, multi-user)

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Re-login (new shell / new SSH session) after install so the Nix env is picked up.

## 3. Trusted user for user-level substituters

Determinate's `determinate-nixd` regenerates `/etc/nix/nix.conf` and will wipe
manual edits made there. Local settings go in `/etc/nix/nix.custom.conf`
instead - append:

```
trusted-users = root krit
```

```bash
sudo systemctl restart nix-daemon
nix config show trusted-users   # should print: root krit
```

Confirmed working via `/etc/nix/nix.custom.conf` surviving `determinate-nixd`
regenerations across multiple rebuilds.

## 4. (Optional) linger for user services

Linger defaults to "no" - without it, user-level systemd services (e.g.
`sops-nix.service`) stop when the SSH session ends.

```bash
sudo loginctl enable-linger krit
```

## 5. Copy the sops age key

UGOS's SFTP subsystem breaks `scp`'s relative-path handling, so pipe the key
over `ssh` instead (or use `scp -O` with an absolute path):

```bash
cat ~/.config/sops/age/keys.txt | ssh krit@nicol-nas \
  'cat > ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt'
```

## 6. Clone the repo

```bash
git clone https://github.com/<owner>/nix.git ~/nix
cd ~/nix
git checkout develop
```

HTTPS only at this stage - the SSH remote (`id_github`) doesn't exist yet.
It's provisioned by the first home-manager switch (via sops + `~/.ssh/config`).

## 7. First activation

Status: done - this host is commissioned and on the `develop` branch.
Kept here for reference / re-provisioning after an overlay wipe.

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch \
  -b hm-backup --flake .#krit@Nicol-NAS
```

`-b hm-backup` only needs to be passed explicitly on this first run - the
repo's `sw` alias already includes it for subsequent rebuilds.

## 8. Post-switch checks

```bash
# new SSH session should show starship prompt
ssh krit@nicol-nas

systemctl --user status sops-nix.service

ls ~/.ssh   # expect: id_github  id_github.pub  config  allowed_signers

git remote set-url origin <ssh-url>   # switch the clone over to SSH
```

## 9. Ongoing usage

`sw` is the daily driver for rebuilds on this host.

```bash
sw                 # home-manager switch -b hm-backup (repo alias)
enabledevalcheck   # package audit alias

# for jobs that must survive an SSH disconnect:
tmux new -A -s main
```

Panes inside tmux use a non-login shell on this host
(`set -g default-command "$SHELL"`, gated to home builds) - Debian's
`/etc/profile` resets `PATH` on login shells, and the hm-session-vars guard
prevents re-sourcing it in a nested login shell, so a login-shell pane would
lose the Nix-managed `PATH`.

A tmux **server** started before an activation carries the old environment
forever - it does not pick up changes from a later `sw`. If a big
environment change doesn't seem to have taken effect, or a command that
should exist is suddenly "not found" inside tmux, kill the stale server and
start fresh:

```bash
pkill -x tmux
tmux new -A -s main
```

## 10. Secrets

Common (cross-host) secrets decrypt at activation via the sops-nix user
service. It's a oneshot - `systemctl --user status sops-nix.service` showing
`inactive (dead)` together with a `Main PID exited, code=exited, status=0/SUCCESS`
line in the journal is the **healthy** state, not a failure. Decrypted
secrets land under `$XDG_RUNTIME_DIR/secrets.d/<generation>` with stable
symlinks published under `~/.config/sops-nix/secrets`.

This host also has its own secrets file, `hosts/Nicol-NAS/Nicol-NAS-secrets-sops.yaml`,
encrypted **only** to the `*krit` user age key - unlike the other hosts,
Nicol-NAS has no SSH host key to derive an age key from, so there's no
host-specific recipient. The `.sops.yaml` rule matching it is
`hosts/Nicol-NAS/.*secrets-sops\.yaml$`. It currently holds a single
placeholder value and nothing real yet.

To add a NAS-only secret:

```bash
# from the NAS itself (sops + age are installed there):
sops-host   # alias for: sops hosts/Nicol-NAS/Nicol-NAS-secrets-sops.yaml

# or from any machine that has the krit age key:
sops hosts/Nicol-NAS/Nicol-NAS-secrets-sops.yaml
```

Then declare it in the `users/krit/common/toplevel/sops-secrets.nix` home
block with `sopsFile = nicolNasSecrets;` so it's wired up like the other
per-host secrets files.

Verify the file is still decryptable (e.g. after rotating keys):

```bash
sops -d hosts/Nicol-NAS/Nicol-NAS-secrets-sops.yaml
# expect: placeholder: unused
```

## 11. SSH known_hosts

`~/.ssh/known_hosts` is an immutable symlink into the Nix store, pinning
`gitea-ssh.nicolkrit.ch` and `github.com` (3 official GitHub keys). Since
it's read-only, new/unknown host keys can't be appended to it - they persist
instead to `~/.ssh/known_hosts.local`, a writable file. `UserKnownHostsFile`
in the ssh config lists both files, so TOFU prompts for new hosts still work
normally and get remembered across rebuilds.

If ssh ever reports `Failed to add the host to the list of known hosts`,
that means the managed (store) file is missing a pin worth adding
permanently - add it to `ssh-config.nix` rather than relying on the local
file.

## 12. Git on the NAS

Commits are SSH-signed (signing key comes from sops). The repo's
`core.hookspath = .githooks` pre-commit hook runs `deadnix` and `nix fmt` via
`nix run`, with stderr suppressed for a clean prompt - which means the
**first** commit after a store wipe (or on a fresh clone) silently builds
both tools for a few minutes and looks hung. Options:

```bash
# just wait it out, or pre-warm before committing:
nix run github:astro/deadnix -- --version
nix fmt -- --help

# or skip the hook for that one commit:
git commit --no-verify
```

## 13. Auditing

```bash
enabledevalcheck   # prints this host's sorted home.packages

nix build .#homeConfigurations."krit@Nicol-NAS".activationPackage --dry-run
```

In the dry-run output, only `home-manager-files` / `home-manager-generation`
(plus `activation-script` / `nix.conf` when config actually changed) should
ever appear under "will be built". Any real package compile showing up there
is a regression worth investigating immediately - it happened once before
(the niri `config.kdl` validation build getting pulled into the home-manager
closure).
