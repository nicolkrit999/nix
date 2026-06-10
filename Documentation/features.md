# Features

## Adaptive Host Support

Leverage `denix` to create customized environments per host. Each host can choose which modules to enable and configure their behavior using `constants` — typed variables passed to module logic.

### Host-specific home-manager modules
the `/modules` folder contains system-wide general modules, useful for everyone.

The `/users` folder holds modules separate from system-wide ones, enabling highly opinionated, user/host-specific configurations.

The `/templates` folder holds modules not auto-discovered by denix (files without the delib header, or that must be imported manually).

---

## Hybrid Declarative + Non-Declarative Modules

Some tools are better configured through their own official methods rather than Nix syntax. In these cases a `.nix` file applies basic logic and/or sources an external directory, while the rest of the config lives in its original location.

This enables two scenarios:
1. **With a custom setup** (e.g. stowed from another repo or by using `mkOutOfStoreSymlink`): the `.nix` config and the original file merge — hybrid environment.
2. **Without a custom setup**: only the `.nix` behavior applies; the rest is default.

Currently applies to:
- **Shells**: `zsh.nix`, `bash.nix`, `fish.nix` ↔ `~/.zshrc_custom`, `.bashrc_custom`, `.custom.fish`
- **Caelestia/Noctalia**: `caelestia-main.nix`, `noctalia-main.nix` ↔ `~/.config/caelestia/shell.json`, `~/.config/noctalia/config.json`

---

## Theming

A base16 colorscheme is chosen per host. The user can also enable Catppuccin (which support choosing the accent color) via the official [catppuccin-nix](https://nix.catppuccin.com/) module.

- View available flavors and accents at the [Catppuccin palette](https://catppuccin.com/palette/).
- When Catppuccin is enabled the matching stylix target is disabled to avoid conflicts:

  ```nix
  alacritty.enable = !catppuccin;
  ```

---

## Wallpapers (gif included in window managers)

Wallpapers are host-specific and tied to the monitor list. They apply automatically in all desktop environments and windows managers (except cosmic, currently not working).

- First monitor → first wallpaper, second monitor → second wallpaper, etc
- In KDE Plasma the "primary" monitor takes the first wallpaper — if you change the primary monitor in System Settings, it will get the first wallpaper.
- Using the optional `waypaper` module it is possible to setup using a gui any wallpaper, including videos and wallpaper engines dynamic wallpapers. If waypaper is disabled then the declarative wallpaper set up is completely disabled for window manager, and the chosen wallpaper in the ui is applied inconditionally to any future and present wm
- **waypaper limitation:** waypaper 2.7 cannot set different wallpapers per monitor simultaneously, and does not support wallpaper rotation (portrait monitors receive the same image as landscape ones). For per-monitor wallpapers, use the declarative awww path with `waypaper` disabled.

---

## Multiple Desktop Environments

- **Hyprland** - default tiling window manager.
- **niri** — scroll-based tiling windows manager.
- **MangoWM + mangowc** — Tiling window manager supporting a vast choices of tiling layouts.
- **KDE Plasma** — highly configurable, Windows-like launcher.
- **GNOME** — simple, macOS-like launcher; familiar to Ubuntu/Mint users.
- **Cosmic** — system76's revisited GNOME (currently unstable — expect freezes, black screens on logout, broken keybindings).

### Caelestia & noctalia shell
- Caelestia is available on Hyprland
- Noctalia is available in all WMs
- Potential incompatibility with waybar, hyprlock and similar is already handled and tested using `test-custom-shell`.

### Changing Desktop Environments Safely

> **Warning:** Disabling the DE you are currently using with `nixos-rebuild switch` will immediately drop you into TTY.

**Safe approach — build for next boot:**
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

- **`deep-focus`** — Launches browser, editor, file manager, and terminal into numbered workspaces on login and forces swaync DND mode. Supports both Hyprland and Niri.
- **`guest`** — Ephemeral guest session (see below).
- **`safe-mode`** — Recovery specialization: disables all compositors and theming,allow booting into IceWM via startx, forces bash/xterm/nano, and installs a minimal rescue toolkit (mc, ncdu, parted, btrfs-progs, etc.).
- **`secure-travel`** — Hardened travel mode: kernel sysctl hardening, GNOME-only desktop, ProtonVPN + Tor Browser, MAC address randomization, strict firewall, Quad9 DNS-over-TLS, VPN kill-switch. Disables Tailscale, Bluetooth, nix-ld, nix-alien, and claude-code.

---

## Ephemeral Guest User (Specialization)

A secure, non-persistent account for visitors, implemented as a **NixOS specialization** (`modules/nixos/specializations/guest.nix`). Selecting the `guest` specialization from the bootloader activates it without altering the main system.

- **Credentials**: username and password are both `guest`.
- **Autologin** the guest is already logged in after booting into the generation.
- **Restricted**: no `sudo`, no access to the NixOS config.
- **Pre-loaded apps**: browser, file manager, text editor, image viewer, archive manager, calculator and some other tools.
- **Forced DE**: only XFCE is accessible; all other WMs/DEs are disabled by the specialization.
- **Tailscale firewall**: iptables rules block tailscale and the CGNAT range for UID 2000.
- **Resource cap**: systemd slice limits the guest to 75%gb of the total RAM available and a lower CPU weight (90%).
- **Ephemeral home**: the entire home folder is stored in RAM (`tmpfs`) and wiped on every reboot/shutdown.
  - Advantages: protects SSD lifespan, guaranteed privacy (RAM clears on power loss).
  - Disadvantage: uses RAM (can cause freezes on low-RAM systems). The config caps the guest at 25% of system RAM.

To switch from RAM-based to disk-based wiping, remove the `tmpfs` `fileSystems."/home/guest"` block in `guest.nix` and replace it with a systemd oneshot service that `rm -rf`s and recreates `/home/guest` before the login screen starts.

---

## Flakes & Home Manager Integration

Fully declarative management of user dotfiles and applications via home-manager and support for flakes.

---

## Multiple Shells

Choose a shell per host: `bash`, `zsh`, or `fish`.

---

## Optional BTRFS Snapshots

- Enable snapshots with a host-specific retention policy.
- Only available if installed using BTRFS filesystems.
- Neither the filesystem nor the snapshots module are mandatory — if you use a different filesystem, keep the variable `false` or remove the module entirely.

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
    "/etc/logid.cfg"
  ];
};
```

### Critical Requirements

1. **Declare passwords** — `/etc/shadow` is wiped on reboot, so passwords must be set in Nix code.
2. **SOPS key path** — point SOPS to the physical `/persist` path to avoid a boot-time race:
   ```nix
   sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
   ```
3. **`/persist` must exist** — both manual partitioning and disko configs already create this mountpoint.

---

## Cachix Support

Pre-built binaries for this config are hosted on [Cachix](https://app.cachix.org/). With a good internet connection, builds are significantly faster and don't depend on local hardware.

---

## Multi-Architecture Support

> ⚠️ **Best-effort only.** No physical `aarch64-linux` or `aarch64-darwin` (Apple Silicon) machine is available for testing. Cross-compatibility is included where possible but cannot be guaranteed at any given moment. Open an issue if you encounter a problem.

- `x86_64-linux`
- `aarch64-linux`. For this architecture there are some tests suits that enable the majority of modules and evaluate, this should catch most of the incompatibilities
- `aarch64-darwin` (macOS via nix-darwin)

