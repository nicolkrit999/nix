# The school specialisation is its own user: krit-school

`specializations.school` (`users/krit/nixos/specializations/school.nix`) runs as a dedicated account `krit-school`, not as `krit` with a workspace folder. Selecting the boot entry gives a separate SDDM login; both accounts can exist on the same machine.

## Design

- **No `krit` in the spec.** `constants.user` is forced to `krit-school` (uid 1001, subuid/subgid 165536/65536 next to the personal range). `users.users.krit` and `home-manager.users.krit` do not exist in the specialisation, and nothing in it is owned by or placed under `/home/krit`. The spec must never reference the personal user; the tests (`nixos-spec-school`, `nixos-spec-contract`) enforce it.
- **home-manager follows `constants.user`.** See `Documentation/usage/denix/home-user-follows-constants.md` for the flake extension that makes this work.
- **Workspace is `$HOME`.** No `.school-workspace` anywhere; terminals, nvim and yazi start in `$HOME`. Layout: `~/Projects` comes from the XDG user dirs, the year folders are `~/Documents/year/{1st,2nd,3rd}/<n>-semester`, plus `~/.learning` and `~/distrobox-bin`. `xdg.userDirs.music = null` (no `~/Music`; Templates and Public are kept). An activation step runs a non-recursive, bottom-up `rmdir` on the old empty `~/year/...` and `~/projects` leftovers: it refuses non-empty directories, mountpoints and symlinks, so nothing is ever deleted recursively.
- **Secrets.** `krit.commonSopsSecrets.personalSecrets = false` drops the personal SSH identity and the Hevy key; the shared tokens (nix PAT, attic, cachix) belong to root. The Claude MCP keys (13) and `cf_account_id` / `cf_api_token` are declared by `claude-code-personal`, which is on in school, so they are owned by `krit-school` (see "Claude stack"). The school-only keys (`school_ssh_key`, `school_ssh_pub`, `rclone_school_onedrive_conf`, laptop `school_supsi_password`) come from `krit-common-secrets-sops.yaml`. **They must exist in the yaml at build time** (sops-nix manifest check), otherwise the specialisation does not build. Agents have no sops access: the user adds the keys.
- **Mounts.** Only `University/*` OpenCloud spaces over davfs under `~/opencloud` (no `Personal`); OneDrive via `rcloneMount` (see `school-onedrive-sops-seed.md`). Tailscale is forced on (OpenCloud is tailnet-only).
- **Desktops.** Hyprland and KDE Plasma only. SDDM themes take their images from the shared asset directory (`sddm-astronaut.assetsDir` / `sddm-pixie.assetsDir`) because the new user has no `users/<user>/src/sddm/`.
- **Zen.** `krit.programs.zen-browser.universityOnly = true`: only the University container, space and pins.
- **Dotfiles.** `school-dotfiles-clone` (user oneshot, `ConditionPathExists=!%h/dotfiles`, retried every 30 s) clones the public dotfiles into `~/dotfiles` once. It only ever runs `git clone` into a temp dir and a guarded `mv`; it never pulls, resets or cleans. The private dotfiles mapping and the wallpapers link are off.
- **Claude config.** `school-claude-sync` (system oneshot at boot) copies `dotfiles-private/claude/school` of the **personal** checkout (`skills`, `agents`, `commands`, `.mcp.json`) into the school home. `--delete` applies only inside those three directories. A missing source is not an error.
- **Git and SSH.** Signing and auth use the university key `~/.ssh/id_school` for `github.com`, `gitlab.com` and `gitlab-edu.supsi.ch`. `allowed_signers` holds only the school identity (`extraAllowedSigners = []`: the personal `nicolkrit999` signer is not trusted in this home). The `github.com` ed25519 host key is pinned in `/etc/ssh/ssh_known_hosts` for the spec. The uni account has access to the course repo: `cd ~/Projects && git clone git@github.com:nicolkrit999/developing-projects.git`.
- **Borg.** Backup sources follow the base user; `/home/krit-school` is not backed up.

## Module stack

Off in school (forced `enable = false` where the option exists on the host): the personal clouds, NAS / borg / OpenCloud-mount / smb / sshfs, windows-mount, snapshots, ssh-config, local-packages, flatpak, the PWAs module (school PWAs are declared in the spec), thunderbird, npm, openlogi, proton-cli, concord, prismlauncher, dolphin personal layer, dotfiles-private, network-tools and every desktop except Hyprland and KDE Plasma.

On in school: the Claude stack (`claude-code-wrappers`, `claude-code-personal`, claude-desktop), `agent-reach`, the common and krit Discord modules (`concord` stays off), `vikunja-desktop`, `spotifyAdblock` and `sidra`.

Packages: plain `brave`, `vscode` and `intellij-idea` (no `-school` wrappers), `proton-pass`, `drawio`, `pay-respects`, `tealdeer`, `teams-for-linux`. The iCorsi, SUPSI Portal and other school PWAs launch through `brave --app`; the iCorsi and SUPSI icons are real PNGs (touch icon, converted favicon).

## Claude stack

- **Personal keys in the school user.** Because `claude-code-personal` is on, the school user holds the personal MCP API keys and the Cloudflare image keys, owned by `krit-school`. This is an explicit choice, with the usual risk: anything running as `krit-school` can read them, and the account is a university-facing environment. Switch `claude-code-personal` off in the spec to drop them.
- **Connector scope.** `krit.programs.claude-code-wrappers.connectorWorkspaces` (home-relative paths; `""` is the home directory itself) decides where the Calendar and Gmail connectors stay enabled in the `cai` launcher. Defaults: `[ "school-workspace" ]` on Darwin, `[]` on NixOS. School sets `[ "" ]`, so both work in the whole school home; Higgsfield and Google Drive stay limited to `~/momentary`.
- **Office skill dependencies.** The docx/xlsx/pptx skills need `docx`, `pptxgenjs`, `react`, `react-dom`, `react-icons` and `sharp`. They are built from `users/krit/common/programs/claude-code/office-node` (`package.json` + lock, `buildNpmPackage`) and exposed only through `NODE_PATH`, which `cai` sets when started below `~/momentary` or a `connectorWorkspaces` path (`""` = all of `$HOME`, so the whole school home). Python (openpyxl, pandas, markitdown, defusedxml, lxml), pandoc, poppler and LibreOffice come from the same module's system packages. Update the Node set with `npm install --package-lock-only --ignore-scripts` in that folder, then refresh `npmDepsHash`.
- **agent-floor.** The service runs, but the `agent-floor hook claude` hooks live in the personal `dotfiles-private` `settings.json`, which `krit-school` does not have, so no hooks fire. They could be added through `school-claude-sync`.

## Yazi go-to keys

`krit.programs.yazi` has the options `goToExclude` (second keys of default `g` chords to drop) and `goToExtra` (chords appended after the defaults); the defaults leave the keymap unchanged. School drops `gn` (flake dir), `gm` (`/mnt`) and the old `gP` (dev-environments), and adds `gP` = `~/Projects`, `go` = `~/opencloud`, `gO` = `~/oneDrive`, `gy` = `~/Documents/year`, `gT` = `~/Templates`, `gS` = `~/Public`. `gc gd gD gp gv g. gt gM` are kept.

## Zen on a fresh profile

Zen's home-manager module seeds spaces, pins and shortcuts by patching `zen-sessions.jsonlz4` and `zen-keyboard-shortcuts.json`, files Zen only creates on its first launch. The first session of a new profile (e.g. `krit-school`) therefore starts as plain default Zen.

One-time step: open Zen once, quit it fully, then reboot. The next activation of `home-manager-krit-school.service` applies the University space, container 4, the 8 pins and the shortcuts, and fetches the 5 theme mods. The boot-time activation runs before the network is up, so mods that failed to download are retried on the next activation. The result lives in the profile on `/home` and persists.

## Pinned KDE launchers

The spec overrides `myconfig.programs.kde.pinnedApps` on purpose: the host list pins apps that do not exist in school (github-desktop, proton-pass, Actual, ZapZap, ...). School pins, in order: `zen-beta`, the terminal, `yazi`, `custom-nvim`, `school-pwa-icorsi`, `school-pwa-supsi-portal`, `code`, `intellij-idea`, OBS and LocalSend. Do not sync it back to the host list; add new school pins only for desktop ids present in the school generation.

## LocalSend

LocalSend is enabled in school. It opens TCP and UDP 53317 on all interfaces, including the university Wi-Fi.

## The `/home` mount and the home tmpfiles rule

`fileSystems."/home".neededForBoot = true` is set in `hosts/nixos-laptop/system.nix` and `hosts/nixos-desktop/system.nix`. The school spec adds a non-recursive `d <home> <homeMode> <user> <group> -` tmpfiles rule for its home.

- **Why.** On a tmpfs-root host the initrd created the home directory before the real `/home` was mounted, leaving it root-owned/wrong-owned on the underlying filesystem.
- **What the rule does.** It repairs an existing wrong-owned home on every boot (ownership and mode of the directory itself only, nothing below it).
- **New users.** Any new user on a tmpfs-root host needs the same explicit home rule.

## First-boot checklist

Runtime checks verified live on 2026-11-02:

- SDDM shows only `krit-school`.
- The home-manager activation log lines for `home-manager-krit-school.service` show a clean activation.
- `systemctl --user --failed` is empty.

## Data safety

- The old `/home/krit/.school-workspace` is **never touched by Nix** (no tmpfiles, activation or unit references it any more). It may hold davfs/rclone mountpoints; deleting through a live mount would delete remote data.
- It was removed by hand on 2026-11-02 with `Documentation/troubleshooting/school-workspace-cleanup.sh` (run as `krit` from the default profile). The script is kept for the same situation on another machine; root-owned empty davfs mountpoint dirs left behind need `sudo rmdir`, deepest first (never `rm -r`). It is a dry run by default (`--really` deletes). It refuses when anything is mounted at or below the tree, when the path is a symlink or resolves outside `$HOME`, when the tree is unreadable (stale FUSE), and it never crosses filesystems.
- Copy anything you want to keep (course files, git repos) into `/home/krit-school` before running it.

## Not migrated (redo by hand as krit-school)

- Brave, VS Code and IDEA profiles (fresh profiles; sign in again).
- Podman containers: the school user has its own storage, re-run `school-distrobox-setup`.
- rclone OneDrive config: seeded from sops, re-auth if SUPSI invalidated the token (see `school-onedrive-sops-seed.md`).
- Claude login (`claude` in the school home).

## SQL Developer RPM

The Oracle RPM is not in the repo (licence). It is read from the OpenCloud General space: `~/opencloud/University/0001-General/software/oracle-sql-developer/sqldeveloper-*.noarch.rpm`. `school-distrobox-setup` resolves it once on the host (`school-sqldeveloper-rpm-resolve`), copies it to a plain file under `~/.cache/school-distrobox/` (the davfs automount is not visible inside distrobox) and passes that staged path to the container as one argument. The stage file and its directory are removed after the install (also on failure or SIGTERM); a stage failure (no space, failed or truncated copy) exits `1`. Resolver exit codes: `0` found (path on stdout), `10` General space not mounted (state unknown), `11` mounted but no RPM (upload hint). Setup treats 10 as blocked (nothing installed) and the setup script then exits `3`; 11 is a real failure.

## Only testable at runtime

Offline builds and tests cannot show: the first login (session choice in SDDM, Plasma vs Hyprland), the davfs automounts working as the new user (credentials from `/etc/davfs2/secrets`, `davfs2` group), the University-only Zen profile opening with the expected space, and the actual Plasma and Hyprland logins. Check these on first boot of the specialisation.
