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

```bash
sw                 # home-manager switch -b hm-backup (repo alias)
enabledevalcheck   # package audit alias

# for jobs that must survive an SSH disconnect:
tmux new -A -s main
```
