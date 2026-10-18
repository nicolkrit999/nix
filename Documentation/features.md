# Features

## Adaptive Host Support

Leverage `denix` to create customized environments per host. Each host can choose which modules to enable and configure their behavior using `constants` - typed variables passed to module logic.

### Host-specific home-manager modules
the `/modules` folder contains system-wide general modules, useful for everyone.

The `/users` folder holds modules separate from system-wide ones, enabling highly opinionated, user/host-specific configurations.

The `/templates` folder holds modules not auto-discovered by denix (files without the delib header, or that must be imported manually).

---

## Hybrid Declarative + Non-Declarative Modules

Some tools are better configured through their own official methods rather than Nix syntax. In these cases a `.nix` file applies basic logic and/or sources an external directory, while the rest of the config lives in its original location.

This enables two scenarios:
1. **With a custom setup** (e.g. stowed from another repo or by using `mkOutOfStoreSymlink`): the `.nix` config and the original file merge - hybrid environment.
2. **Without a custom setup**: only the `.nix` behavior applies; the rest is default.

Currently applies to:
- **Shells**: `zsh.nix`, `bash.nix`, `fish.nix` ↔ `~/.zshrc_custom`, `.bashrc_custom`, `.custom.fish`
- **Caelestia**: `caelestia-main.nix` ↔ `~/.config/caelestia/shell.json`
- **Noctalia**: `noctalia-main.nix` writes `~/.config/noctalia/config.toml`; GUI changes go to `~/.local/state/noctalia/settings.toml`, which overrides it

---

## Theming

A base16 colorscheme is chosen per host. The user can also enable Catppuccin (which support choosing the accent color) via the official [catppuccin-nix](https://nix.catppuccin.com/) module.

- View available flavors and accents at the [Catppuccin palette](https://catppuccin.com/palette/).
- When Catppuccin is enabled the matching stylix target is disabled to avoid conflicts:

  ```nix
  alacritty.enable = !catppuccin;
  ```

---

## Wallpapers (video and gif included in window managers)

Wallpapers are host-specific and tied to the monitor list. They apply automatically in all desktop environments and windows managers (except cosmic, currently not working).

- First monitor → first wallpaper, second monitor → second wallpaper, etc
- An entry targeted at `*` is a fallback: it applies only to outputs without their own entry, including monitors hot-plugged later that the host file does not declare. It never stacks under a declared monitor, and mirrored or disabled outputs get no wallpaper.
- On Hyprland, niri and MangoWM one supervisor (`<wm>-wallpaperd`) owns all wallpaper processes: it reconciles on output changes, retries failed starts, restarts a crashed `mpvpaper`, and reconnects if the compositor event stream drops without killing running wallpapers. A second instance exits immediately (lock).
- The supervisor is not a denix module and has no enable toggle. It lives in `modules/nixos/programs/de-wm/wallpaperd/` (`mk-wallpaperd.nix` turns the `wallpapers` list into per-output `OUTPUT=video|image:/nix/store/...` arguments and packages `wallpaperd.sh` with only the tools it needs). That folder is excluded from denix auto-discovery in `flake.nix`; `hyprland-main.nix`, `niri-main.nix` and `mango-main.nix` import it directly, so it runs whenever one of those WMs is enabled. It starts nothing when `skwdWall` is enabled, when a shell owns the wallpaper (caelestia/noctalia on Hyprland, noctalia on niri/MangoWM), or when the `wallpapers` list is empty.
- In KDE Plasma the wallpapers are written by plasma-manager (`programs.plasma.workspace.wallpaper`) and the "primary" monitor takes the first wallpaper - if you change the primary monitor in System Settings, it will get the first wallpaper. On hosts without catppuccin the stylix KDE target owns the colours only (`useWallpaper = false`), so it never re-applies its own wallpaper over these.
- GNOME always uses one static image (the primary wallpaper entry, or the fallback wallpaper when that entry has no `wallpaperURL`) shown on every monitor, regardless of the `skwdWall` toggle below - Mutter has no wlr-layer-shell support, so skwd-wall cannot render there.
- Enabling `programs.skwdWall` installs and enables [skwd-wall](https://github.com/liixini/skwd-wall)/skwd-deck, a GUI-driven wallpaper daemon supporting per-monitor wallpaper types (static/gif/video/Wallpaper Engine scenes, mixed across monitors) with live hotplug persistence. When enabled, it takes over Hyprland, niri, MangoWM, and KDE Plasma completely - the declarative `wallpapers` setup below is fully disabled on those four, and whatever is chosen in skwd-wall's UI applies unconditionally to any present and future window manager among them. skwd-wall is x86_64-linux only; its per-monitor state (`outputs.json`, `monitors.json`, etc.) is owned entirely by its own daemon and is never touched by Nix.

### Static vs. gif vs. video: two engines, one priority order

On the wlroots WMs (Hyprland, niri, MangoWM) each `wallpapers` entry can set `wallpaperURL` (static), `gifURL`, and/or `videoURL` at the same time. Only one is ever played per entry, chosen by priority **video > gif > static** - whichever most-specific field is non-empty wins, so setting a `videoURL` makes any `gifURL`/`wallpaperURL` on the same entry dead weight.

Two different tools render the result, split by content type rather than one tool doing everything:

- **`mpvpaper`** plays `videoURL` and `gifURL` entries (kind `video` in `mk-wallpaperd.nix`), with `loop mute=yes panscan=1.0`. It's an mpv wrapper, so it's the correct tool for anything with frames to decode/loop.
- **`awww`** plays `wallpaperURL` (static-only) entries.

**Why not just use mpvpaper for everything, including static images?** It technically can render a still image, but doing so hits [mpvpaper upstream issue #82](https://github.com/GhostNaN/mpvpaper/issues/82): with no next frame to advance to, mpv's render loop spins and pins a CPU core indefinitely. It's a bug, not a missing feature - but it makes mpvpaper the wrong choice for static content specifically. `awww` has no such issue and is purpose-built for static wallpapers, so both stay available and the engine is picked per entry based on which URL field is set. `awww-daemon` is only started when at least one entry is a still image.

Practical implication: only add a `videoURL`/`gifURL` to an entry when you actually want animated/video content there - leaving both empty is what keeps an entry on the `awww` static path.

---

## Multiple Desktop Environments

- **Hyprland** - default tiling window manager.
- **niri** - scroll-based tiling windows manager.
- **MangoWM + mangowc** - Tiling window manager supporting a vast choices of tiling layouts.
- **KDE Plasma** - highly configurable, Windows-like launcher.
- **GNOME** - simple, macOS-like launcher; familiar to Ubuntu/Mint users.
- **Cosmic** - system76's revisited GNOME (currently unstable - expect freezes, black screens on logout, broken keybindings).

### Caelestia & noctalia shell
- Caelestia is available on Hyprland (x86_64 only)
- Noctalia is available on Hyprland, niri and MangoWM (x86_64 only)
- Potential incompatibility with waybar, hyprlock and similar is already handled and tested using `nixos-custom-shells`.

### Portals

xdg-desktop-portal backends are chosen per session through `<desktop>-portals.conf` (`modules/nixos/toplevel/xdg-portal.nix`): each of Hyprland, KDE, GNOME, COSMIC, niri and mango gets its own backend order, and the Secret portal is routed to gnome-keyring everywhere. Interfaces a desktop does not support are routed to `none`, so xdg-desktop-portal's deprecated `UseIn=` fallback cannot pick another desktop's backend (e.g. kde.portal in COSMIC or mango); `test-portal-routing` checks the selected backend per session without switching. Pitfalls and a diagnosis recipe: `Documentation/usage/gotchas/xdg-desktop-portal-nixos.md`.

### Changing Desktop Environments Safely

> **Warning:** Disabling the DE you are currently using with `nixos-rebuild switch` will immediately drop you into TTY.

**Safe approach - build for next boot:**
```bash
cd ~/nix
sudo nixos-rebuild boot --flake .
# then reboot
```

**Emergency recovery (if already dropped to TTY):**
```bash
cd ~/nix && sw
```
If your normal user shell fails, log in as `root` and run:
```bash
cd /home/<your-user>/nix
nix-shell -p git --command "git config --global --add safe.directory '*'"
nixos-rebuild boot --flake .
reboot
```

**Issue: "File .../hyprland.conf would be clobbered"**
```bash
rm ~/.config/hypr/hyprland.conf && sw
```

---

## NixOS Specializations

Specializations are bootloader entries that apply an alternative NixOS configuration overlay at boot. Enabling the module adds the entry; the base system is unaffected unless that entry is selected. The following specializations are available:

- **`deep-focus`** - Replaces the Hyprland, Niri and Mango autostart with browser, editor, file manager and terminal only (numbered workspaces on Hyprland, staggered launches on Niri and Mango; no zapzap/YouTube) and turns swaync DND on. DND only takes effect when swaync is the active notification daemon (not under caelestia/noctalia).
- **`guest`** - Ephemeral guest session (see below).
- **`safe-mode`** - Recovery specialization (boot entry tag `safemode-tty`): disables all compositors, display managers and theming, boots to a TTY login where IceWM starts via `startx`, forces bash/xterm/nano, and installs a minimal rescue toolkit (mc, ncdu, parted, btrfs-progs, etc.).
- **`secure-travel`** - Hardened travel mode: kernel sysctl hardening, GNOME-only desktop, browsers limited to Tor Browser and LibreWolf with its Privacy profile as the default (Zen, the PWAs and the stock Firefox/Chromium/Helium are forced off), MAC address randomization, strict firewall, Quad9 nameservers with opportunistic DNS-over-TLS. The VPN is Tailscale with a Mullvad exit node picked by hand (`tailscale exit-node list`, `tailscale set --exit-node=<name>`); a home-manager user timer sends a desktop notification every 2 minutes while Tailscale is not running or no exit node is set. This is advisory only, there is no kill switch. The firewall's allowed TCP/UDP port lists are forced empty, and inbound attack surface is switched off: sshd, avahi, localsend, docker, LLMNR and mDNS in systemd-resolved, and GNOME remote desktop / user sharing. Bluetooth stays installed but the adapter is not powered on at boot (`autoEnableOnBoot` off), so headphones can be enabled at runtime. nix-ld, nix-alien and claude-code are disabled. Tailscale stays on (`tailscale0` is not a trusted interface and `openFirewall` is off), while the NAS consumers that need the tailnet (smb, opencloud-mount, sshfs, borg backups) are disabled in this specialization. Checked against the real hosts by `spec-real-hosts-security`.

---

## Ephemeral Guest User (Specialization)

A secure, non-persistent account for visitors, implemented as a **NixOS specialization** (`modules/nixos/specializations/guest.nix`). Selecting the `guest` specialization from the bootloader activates it without altering the main system.

- **Credentials**: username and password are both `guest`.
- **Autologin** the guest is already logged in after booting into the generation.
- **Restricted**: no `sudo`, no access to the NixOS config.
- **Pre-loaded apps**: Firefox, file manager, text editor (Mousepad), screenshot tool and archive manager (File Roller).
- **Forced DE**: only XFCE is accessible; all other WMs/DEs are disabled by the specialization.
- **No krit services**: tailscale, sshd, avahi, localsend, docker/podman, the NAS/cloud/Windows mounts, borg backups and the krit user-manager linger are switched off; the guest is not in the `networkmanager` group, is not allowed to use the nix daemon and cannot read the GitHub token secret (mode 0400).
- **Resource cap**: systemd slice limits the guest to 75% of the total RAM available and a lower CPU weight (90%).
- **Ephemeral home**: the entire home folder is stored in RAM (`tmpfs`) and wiped on every reboot/shutdown.
  - Advantages: protects SSD lifespan, guaranteed privacy (RAM clears on power loss).
  - Disadvantage: uses RAM (can cause freezes on low-RAM systems). The config caps the guest at 25% of system RAM.

To switch from RAM-based to disk-based wiping, remove the `tmpfs` `fileSystems."/home/guest"` block in `guest.nix` and replace it with a systemd oneshot service that `rm -rf`s and recreates `/home/guest` before the login screen starts.

---

## Flakes & Home Manager Integration

Fully declarative management of user dotfiles and applications via home-manager and support for flakes. Packages come from nixos-unstable by default; a permanent stable nixpkgs input (`pkgsStable`) is available to pin individual packages.

---

## Multiple Shells

Choose a shell per host: `bash`, `zsh`, or `fish`.

---

## Default Applications

The apps opened for each file family are picked per host with constants (NixOS): `terminal`, `browser`, `editor`, `fileManager`, plus `videoPlayer`, `audioPlayer`, `imageViewer`, `pdfViewer`, `docEditor`, `sheetEditor`, `slideEditor` and `archiveManager` (defaults mpv, gwenview, zathura, libreoffice, ark). Each value is a package name, a flatpak app id or a `.desktop` id; the chosen app is installed once and set as the MIME default.

- An app that a dedicated module already provides (e.g. `programs.firefox.enable`, a custom neovim module) is not installed a second time; the MIME default points at that module's desktop entry.
- An unknown name installs nothing and raises an evaluation warning; a role override that is not present falls back to the role's default with one warning.
- `extraAppPackages` installs extra packages for overrides given as a desktop id (e.g. `docEditor = "org.kde.kate.desktop"` with `extraAppPackages = [ "kate" ]`).

---

## Airplane Mode

On NixOS hosts with NetworkManager, `airplane` turns off only Wi-Fi or every radio (Wi-Fi, WWAN, Bluetooth and the rest) and confirms the result by reading each radio back. Run it with no argument for a menu, or use `airplane-on` / `airplane-off`. On waybar a pill shows the state: left click toggles with the last chosen scope, right click picks the scope.

---

## Optional BTRFS Snapshots

- Enable snapshots with a host-specific retention policy.
- Only available if installed using BTRFS filesystems.
- Neither the filesystem nor the snapshots module are mandatory - if you use a different filesystem, keep the variable `false` or remove the module entirely.

---

## BTRFS Scrub

- Every host with btrfs filesystems gets an automatic monthly scrub of one mount point per btrfs device (set in `common-configuration`, nothing to enable); hosts without btrfs get none.

---

## Single Secret Service Provider

- gnome-keyring is the only `org.freedesktop.secrets` provider on every host and in every DE/WM session, unlocked at login through PAM (login and sddm). In the guest specialisation the keyring is started but stays locked, since autologin has no password; the guest gets one new-keyring password prompt per boot.
- KWallet is not a second store: `kwalletd6` runs only as a compatibility frontend into gnome-keyring, `ksecretd` is off and its D-Bus names are stubbed.
- gcr-ssh-agent is the only SSH agent; gpg-agent keeps GPG only.
- The Secret portal is routed to gnome-keyring in every session, and all Chromium/Electron apps are pinned to `--password-store=gnome-libsecret` (`modules/nixos/toplevel/libsecret-pinning.nix`).
- Details and pitfalls: `Documentation/usage/gotchas/secret-service-single-provider.md`.

---

## SOPS-nix Secret Management

- SOPS is pre-wired in `flake.nix`; `.sops.yaml` contains the structure for adding host-specific keys.
- For new hosts reusing the `nixos-desktop` name: wipe its existing content, generate a new host key, and re-invite the host:
  ```bash
  nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
  sops updatekeys hosts/nix-desktop/optional/host-sops-nix/<hostname>-secrets-sops.yaml
  ```

---

## Impermanence

Root (`/`) is wiped clean on every reboot via `tmpfs`. System drift is impossible; the system is always in a known declarative state.

### How to Persist Data

Add directories or files to your host config:
```nix
environment.persistence."/persist" = {
  directories = [
    # folders to keep across reboots
  ];
  files = [
    "/etc/machine-id"
  ];
};
```

### Critical Requirements

1. **Declare passwords** - `/etc/shadow` is wiped on reboot, so passwords must be set in Nix code.
2. **SOPS key path** - point SOPS to the physical `/persist` path to avoid a boot-time race:
   ```nix
   sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
   ```
3. **`/persist` must exist** - both manual partitioning and disko configs already create this mountpoint.

---

## Cachix Support

Pre-built binaries for this config are hosted on [Cachix](https://app.cachix.org/). With a good internet connection, builds are significantly faster and don't depend on local hardware.

---

## Multi-Architecture Support

> ⚠️ **Best-effort only.** No physical `aarch64-linux` or `aarch64-darwin` (Apple Silicon) machine is available for testing. Cross-compatibility is included where possible but cannot be guaranteed at any given moment. Open an issue if you encounter a problem.

- `x86_64-linux`
- `aarch64-linux`. For this architecture there are some tests suits that enable the majority of modules and evaluate, this should catch most of the incompatibilities
- `aarch64-darwin` (macOS via nix-darwin)

---

## Tests & CI

- `templates/tests/` holds auto-discovered tests (`nixos/`, `common/`, `darwin/`): every folder with a `check-*.sh` and/or `*_test.nix` is one test, with an optional `test.conf` (CI group, timeout, platforms). There is no registry to edit, and a folder matching no pattern is an error.
- Run them with `bash templates/tests/run-tests.sh` (`--parallel`, `--fast`, `--list`, `--only <name>`, `--keep-logs`, `--prune-only`). Logs land in `~/.local/state/nix-tests/<timestamp>-<sha>/` (with a `latest` link) and old runs are pruned (20 runs / 60 days / 500 MB).
- Coverage includes the spec contracts (guest, secure-travel, school), secret service, wallpapers and the wallpaper supervisor, the screenshot folder being identical across every DE/WM/shell, keybind conflicts, NAS mounts, tailscale, state-version freeze, and cross-arch evaluation.
- In CI, `tests-nixos.yml` and `tests-darwin.yml` build a matrix from the same discovery, run each test with a per-test timeout and a complete log, upload the logs as an artifact, and fail the leg when any test fails. A final job sends a Discord report with the logs attached. See `Documentation/usage/ci/build-workflows.md`.
