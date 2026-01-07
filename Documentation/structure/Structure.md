# 📂 Project Structure

This repository separates the **System Configuration** (root-level/OS) from the **User Configuration** (home-manager/apps).

This guide contains an in-depth analysis of every file

Categories can be navigated with the links below:

* **[❄️ Core Configuration](./sections/Core.md)**: Entry point (`flake.nix`), inputs, and global variables.
* **[⚙️ System Modules (NixOS)](./sections/NixOS.md)**: Bootloader, hardware, networking, and user management.
* **[🏠 User Modules (Home Manager)](./sections/HomeManager.md)**: Applications, themes, Hyprland, and shell customization.


## 🌳 File Tree

```text
.

├── flake.nix
├── home-manager
│   ├── home.nix
│   ├── home-packages.nix
│   └── modules
│       ├── cli-programs
│       │   ├── default.nix
│       │   ├── neovim.nix
│       │   ├── swaync
│       │   │   └── default.nix
│       │   ├── waybar
│       │   │   ├── default.nix
│       │   │   └── style.css
│       │   └── wofi
│       │       ├── default.nix
│       │       └── style.css
│       ├── core.nix                        # It import the folders inside home-manager-modules
│       ├── de-wm
│       │   ├── caelestia
│       │   │   ├── caelestia-config.nix
│       │   │   ├── caelestia-main.nix
│       │   │   ├── caelestia-wallpaper.nix
│       │   │   └── default.nix
│       │   ├── cosmic
│       │   │   ├── cosmic-main.nix
│       │   │   └── default.nix
│       │   ├── default.nix
│       │   ├── gnome
│       │   │   ├── default.nix
│       │   │   ├── gnome-binds.nix
│       │   │   └── gnome-main.nix
│       │   ├── hyprland
│       │   │   ├── default.nix
│       │   │   ├── hyprland-binds.nix
│       │   │   ├── hyprland-hypridle.nix
│       │   │   ├── hyprland-hyprlock.nix
│       │   │   ├── hyprland-hyprpaper.nix
│       │   │   └── hyprland-main.nix
│       │   └── kde
│       │       ├── default.nix
│       │       ├── kde-binds.nix
│       │       ├── kde-desktop.nix
│       │       ├── kde-files.nix
│       │       ├── kde-inputs.nix
│       │       ├── kde-krunner.nix
│       │       ├── kde-kscreenlocker.nix
│       │       ├── kde-main.nix
│       │       └── kde-panels.nix
│       ├── gui-programs
│       │   └── default.nix
│       └── utilities
│           ├── bat.nix
│           ├── default.nix
│           ├── eza.nix
│           ├── git.nix
│           ├── lazygit.nix
│           ├── mime.nix
│           ├── qt.nix
│           ├── starship.nix
│           ├── stylix.nix
│           ├── tmux.nix
│           └── zsh.nix
├── hosts
│   └── template-host
│       ├── configuration.nix
│       ├── disko-config.nix
│       ├── optional
│       │   ├── default.nix                     # It import the optional host-specific folders
│       │   ├── general-hm-modules
│       │   │   ├── default.nix
│       │   │   ├── home.nix
│       │   │   └── modules.nix
│       │   ├── host-hm-modules
│       │   │   └── default.nix
│       │   ├── host-packages
│       │   │   ├── default.nix
│       │   │   ├── flatpak.nix
│       │   │   └── local-packages.nix
│       │   └── host-sops-nix                   # Empty but present in case it's needed
│       └── variables.nix
├── LICENSE.txt
├── nixos
│   └── modules
│       ├── audio.nix
│       ├── bluetooth.nix
│       ├── boot.nix
│       ├── core.nix
│       ├── cosmic.nix
│       ├── env.nix
│       ├── gnome.nix
│       ├── guest.nix
│       ├── home-manager.nix
│       ├── hyprland.nix
│       ├── kde.nix
│       ├── kernel.nix
│       ├── net.nix
│       ├── nh.nix
│       ├── nix.nix
│       ├── sddm.nix
│       ├── snapshots.nix
│       ├── tailscale.nix
│       ├── timezone.nix
│       ├── user.nix
│       └── zram.nix
```


