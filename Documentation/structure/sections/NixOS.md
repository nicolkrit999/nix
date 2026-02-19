- [⚙️ NixOS (`nixos/modules/`)](#️-nixos-nixosmodules)
  - [`audio.nix`](#audionix)
  - [`bluetooth.nix`](#bluetoothnix)
  - [`boot.nix`](#bootnix)
  - [`cachix.nix`](#cachixnix)
  - [`common-configuration.nix`](#common-configurationnix)
  - [`core.nix`](#corenix)
  - [`cosmic.nix`](#cosmicnix)
  - [`env.nix`](#envnix)
  - [`gnome.nix`](#gnomenix)
  - [`guest.nix`](#guestnix)
  - [`home-manager.nix`](#home-managernix)
  - [`hyprland.nix`](#hyprlandnix)
  - [`kde.nix`](#kdenix)
  - [`kernel.nix`](#kernelnix)
  - [`net.nix`](#netnix)
  - [`nh.nix`](#nhnix)
  - [`niri.nix`](#nirinix)
  - [`nix.nix`](#nixnix)
  - [`sddm.nix`](#sddmnix)
  - [`snapshots.nix`](#snapshotsnix)
  - [`tailscale.nix`](#tailscalenix)
  - [`timezone.nix`](#timezonenix)
  - [`user.nix`](#usernix)
  - [`zram.nix`](#zramnix)

# ⚙️ NixOS (`nixos/modules/`)

These modules control the Operating System itself. Changes here affect boot, hardware, and networking.

## `audio.nix`

Enables Pipewire, PulseAudio compatibility, and realtime scheduling for low-latency audio.

## `bluetooth.nix`

Enables the Bluetooth hardware and software stack (BlueZ) and management tools (Blueman).

- It is set to enable bluetooth on boot and to bypass kernel rfkill list (soft blocking).
  - It is possible to make it not enable at boot by replacing the entire content with

```nix
{
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
```

## `boot.nix`

Configures the bootloader (Systemd-boot). It manages EFI variables and detects other OSes for dual-booting.

## `cachix.nix`

This file configures **Cachix**, a service that speeds up your builds by downloading pre-compiled binaries instead of building everything from scratch.

- **Download (Pull):** Automatically adds your cache URL and public key to Nix settings so the system can fetch binaries.
- **Upload (Push):** If enabled, it securely loads your Auth Token via **sops** and creates a convenient `rebuild-push` alias. This alias rebuilds your system and immediately uploads the new binaries to the cache in one command.

## `common-configuration.nix`

This file serves as the **shared baseline** configuration for every host in your fleet, ensuring consistent behavior across different machines.

- **Core System Identity:** Sets the hostname, networking, time zone, and keyboard layouts.
- **Universal Packages:** Installs essential CLI tools (like `git`, `fzf`, `eza`) and base GUI libraries needed by most applications.
- **Architecture & Security:** Configures critical system-level components, including **Polkit rules** (for `gpu-screen-recorder` permissions) and **binfmt emulation** (allowing your x86 desktop to build software for your ARM laptop).
- **Performance Tweaks:** Enables `system76-scheduler` for responsiveness and `upower` for battery management.

## `core.nix`

Import all the nixos modules. When a module is added in `nixos/modules/` it is necessary to add it here to allow nixos to see it

- Desktop environment should not be added here because they are automatically enabled/disabled depending on the user choices in `variables.nix`

## `cosmic.nix`

This file configures the system-level components required to run the cosmic Desktop Environment.

- **Display Manager Strategy:** It enables the cosmic Desktop Manager but explicitly **does not enable cosmic-greeter**. This is designed to coexist with the existing **SDDM** setup, allowing SDDM to launch GNOME sessions without conflict.
- **Debloat:** It excludes standard "bloatware" packages

## `env.nix`

Sets system-wide environment variables and default application associations.

- **Environment:** Defines variables like `EDITOR` and `PATH` availability.
- **MIME Types:** Explicitly maps directories (`inode/directory`) to the default file manager, ensuring that "Open Folder" actions launch your terminal file manager instead of a graphical one.

## `gnome.nix`

This file configures the system-level components required to run the GNOME Desktop Environment.

- **Display Manager Strategy:** It enables the GNOME Desktop Manager but explicitly **does not enable GDM**. This is designed to coexist with the existing **SDDM** setup, allowing SDDM to launch GNOME sessions without

- **Debloat:** It excludes standard "bloatware" packages like Epiphany (browser), Geary (mail)
- **Conflict Resolution:** It explicitly forces the SSH password prompt tool to use KDE's `ksshaskpass` (`lib.mkForce`) to prevent build errors caused by GNOME attempting to install its own conflicting `seahorse` agent.

## `guest.nix`

This file configures a secure, ephemeral **Guest Mode**, allowing others to use your computer without risking your personal data or internal network.

- **Enforced Ephemeral Session:** Uses a custom `guest-monitor` script that restricts the guest to the **XFCE** desktop. If they attempt to log into your main sessions (Hyprland/Niri), they are immediately logged out. It also warns users that all data will be wiped upon reboot.
- **Network Isolation (Hotel Mode):** Implements strict `iptables` firewall rules that allow internet access but **block** all connections to your local network (NAS, printers, SSH), ensuring the guest cannot snoop on your devices.
- **Restricted Privileges:** The guest user has restricted permissions but is granted a specific `sudo` exception to run `reboot` without a password, allowing them to cleanly wipe their session when finished.

## `home-manager.nix`

Hooks Home Manager into the NixOS rebuild process, allowing `nixos-rebuild` to manage home configurations

## `hyprland.nix`

The system-side enabler. It installs the `Hyprland` binary, configures the session entry for the Display Manager, and enables XWayland support.

## `kde.nix`

This file configures the system-level components required to run the KDE Desktop Environment.

## `kernel.nix`

Sets kernel parameters and loads specific kernel modules required for your hardware support.

## `net.nix`

Configures NetworkManager, sets the system `hostname`, and manages firewall rules.

## `nh.nix`

Configures `nh` (Nix Helper), a CLI tool that speeds up rebuilds and creates visual diffs of changes.

## `niri.nix`

This file is the system-level switch that enables the **Niri** Wayland compositor.

- **Conditional Activation:** It checks the `myconfig.constants.niri` variable. If set to `true` in your host configuration, it activates the module; otherwise, it does nothing.
- **System Integration:** It installs the core `pkgs.niri` package and registers the desktop session, making "Niri" appear as an option in your login manager (SDDM/GDM).

## `nix.nix`

Configures the Nix daemon itself. Enables "Flakes" (experimental feature) and sets up automatic Garbage Collection to save disk space.

## `sddm.nix`

Configuration for the Simple Desktop Display Manager (Login Screen).

- **Wayland:** Enables native Wayland support to ensure correct graphics rendering for Hyprland.
- **Theming:** Uses the official `sddm-astronaut` from official nix packages
- **Security:** Disables `autoLogin`, ensuring the login screen is always presented on boot.
- **Default session:** Automatically set based on which desktop environment is enabled

## `snapshots.nix`

Enable and configure snapshots depending on the retention policy based on `variables.nix`

## `tailscale.nix`

Manage tailscale service

## `timezone.nix`

Sets the system time zone and locale (language, currency formats) settings.

## `user.nix`

Defines user accounts. It creates the `krit` user, assigns the `wheel` (admin/sudo) group, and sets the default login shell to Zsh. Additionally it define autologin to be off.

## `zram.nix`

Enables ZRAM swap, creating a compressed block device in RAM to improve performance when memory is low.
