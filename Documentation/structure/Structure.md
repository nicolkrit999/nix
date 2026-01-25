# 📂 Project Structure

This repository separates the **System Configuration** (root-level/OS) from the **User Configuration** (home-manager/apps).

This guide contains an in-depth analysis of every file

Categories can be navigated with the links below:

- **[❄️ Core Configuration](./sections/Core.md)**: Entry point (`flake.nix`), inputs, and global variables.
- **[⚙️ System Modules (NixOS)](./sections/NixOS.md)**: Bootloader, hardware, networking, and user management.
- **[🏠 User Modules (Home Manager)](./sections/HomeManager.md)**: Applications, themes, Hyprland, and shell customization.

## 🌳 File Tree

```text
├── common
│   └── ... # This is where you can create common modules

├── flake.lock # It must be in the repo to allow cachix to work
├── flake.nix
├── home-manager
│   ├── home-packages.nix
│   ├── home.nix
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
│       ├── de-wm
│       │   ├── caelestia
│       │   │   ├── caelestia-main.nix
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
│       │   ├── kde
│       │   │   ├── default.nix
│       │   │   ├── kde-binds.nix
│       │   │   ├── kde-desktop.nix
│       │   │   ├── kde-files.nix
│       │   │   ├── kde-inputs.nix
│       │   │   ├── kde-krunner.nix
│       │   │   ├── kde-kscreenlocker.nix
│       │   │   ├── kde-main.nix
│       │   │   └── kde-panels.nix
│       │   ├── niri
│       │   │   ├── default.nix
│       │   │   ├── niri-binds.nix
│       │   │   └── niri-main.nix
│       │   └── noctalia
│       │       ├── default.nix
│       │       └── noctalia-main.nix
│       ├── default.nix
│       ├── gui-programs
│       │   └── default.nix
│       └── utilities
│           ├── bash.nix
│           ├── bat.nix
│           ├── default.nix
│           ├── eza.nix
│           ├── fish.nix
│           ├── fzf.nix
│           ├── git.nix
│           ├── lazygit.nix
│           ├── mime.nix
│           ├── qt.nix
│           ├── starship.nix
│           ├── stylix.nix
│           ├── tmux.nix
│           ├── zoxide.nix
│           └── zsh.nix
├── hosts
│   └── template-host
│       ├── configuration.nix
│       ├── disko-config.nix
│       ├── home.nix
│       ├── optional
│       │   ├── default.nix
│       │   ├── general-hm-modules
│       │   │   ├── default.nix
│       │   │   └── modules.nix
│       │   ├── host-hm-modules
│       │   │   └── default.nix
│       │   ├── host-packages
│       │   │   ├── default.nix
│       │   │   ├── flatpak.nix
│       │   │   └── local-packages.nix
│       │   └── host-sops-nix
│       └── variables.nix
├── nixos
│   └── modules
│       ├── audio.nix
│       ├── bluetooth.nix
│       ├── boot.nix
│       ├── cachix.nix
│       ├── common-configuration.nix
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
│       ├── niri.nix
│       ├── nix.nix
│       ├── sddm.nix
│       ├── snapshots.nix
│       ├── tailscale.nix
│       ├── timezone.nix
│       ├── user.nix
│       └── zram.nix
└── README.md
```
