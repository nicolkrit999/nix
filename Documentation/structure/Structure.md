# 📂 Project Structure

This repository leverage denix. This means modules can be put anywhere and do not need nor an import block somewhere nor a default.nix as long as their path is included in `flake.nix`. The modules can therefore be moved at will

This guide contains an in-depth analysis of every file

Categories can be navigated with the links below:

- **[❄️ Core Configuration](./sections/Core.md)**: Entry point (`flake.nix`), inputs, and global variables.
- **[⚙️ System Modules (NixOS)](./sections/NixOS.md)**: Bootloader, hardware, networking, and user management.
- **[🏠 User Modules (Home Manager)](./sections/HomeManager.md)**: Applications, themes, Hyprland, and shell customization.

## 🌳 Current file Tree

```text
.
├── Documentation
│   ├── ideas
│   │   └── ideas.md
│   ├── in-depth-files-expl
│   │   └── files-expl.md
│   ├── issues
│   │   └── issues.md
│   ├── showcase-screenshots
│   │   ├── gnome-showcase.png
│   │   ├── hyprland-caelestia.png
│   │   ├── hyprland-showcase.png
│   │   ├── kde-showcase.png
│   │   ├── noctalia_custom-neovim.png
│   │   ├── noctalia-screen_locker.png
│   │   ├── quickshell-lockscreen.png
│   │   └── xfce-showcase.png
│   ├── structure
│   │   ├── sections
│   │   │   ├── Core.md
│   │   │   ├── HomeManager.md
│   │   │   └── NixOS.md
│   │   └── Structure.md
│   ├── troubleshooting
│   │   └── emergency-recovery-gnu-grub.md
│   └── usage
│       ├── cachix
│       │   └── cachix.md
│       ├── denix
│       │   └── possibilities.md
│       ├── sops
│       │   └── sops-guide.md
│       ├── tmux
│       │   └── tmux-guide.md
│       └── usage-guide-general.md
├── flake.lock
├── flake.nix
├── hosts
│   ├── nixos-desktop
│   │   ├── default.nix
│   │   ├── flatpak.nix
│   │   ├── hardware-configuration.nix
│   │   ├── local-packages.nix
│   │   └── nixos-desktop-secrets-sops.yaml
│   ├── nixos-laptop
│   │   ├── default.nix
│   │   ├── flatpak.nix
│   │   ├── hardware-configuration.nix
│   │   └── local-packages.nix
│   ├── template-host-full
│   │   ├── default.nix
│   │   ├── disko-config.nix
│   │   ├── flatpak.nix
│   │   ├── hardware-configuration.nix
│   │   └── local-packages.nix
│   └── template-host-minimal
│       ├── default.nix
│       ├── disko-config.nix
│       └── hardware-configuration.nix
├── LICENSE.txt
├── modules
│   ├── config
│   │   └── constants.nix
│   ├── programs
│   │   ├── de-wm
│   │   │   ├── cosmic
│   │   │   │   └── cosmic-main.nix
│   │   │   ├── gnome
│   │   │   │   ├── gnome-binds.nix
│   │   │   │   └── gnome-main.nix
│   │   │   ├── hyprland
│   │   │   │   ├── hyprland-binds.nix
│   │   │   │   ├── hyprland-hyprpaper.nix
│   │   │   │   └── hyprland-main.nix
│   │   │   ├── kde
│   │   │   │   ├── kde-binds.nix
│   │   │   │   ├── kde-desktop.nix
│   │   │   │   ├── kde-files.nix
│   │   │   │   ├── kde-inputs.nix
│   │   │   │   ├── kde-krunner.nix
│   │   │   │   ├── kde-kscreenlocker.nix
│   │   │   │   ├── kde-main.nix
│   │   │   │   └── kde-panels.nix
│   │   │   └── niri
│   │   │       ├── niri-binds.nix
│   │   │       └── niri-main.nix
│   │   ├── shells
│   │   │   ├── bash.nix
│   │   │   ├── bat.nix
│   │   │   ├── caelestia
│   │   │   │   └── caelestia-main.nix
│   │   │   ├── eza.nix
│   │   │   ├── fish.nix
│   │   │   ├── fzf.nix
│   │   │   ├── git.nix
│   │   │   ├── lazygit.nix
│   │   │   ├── noctalia
│   │   │   │   └── noctalia-main.nix
│   │   │   ├── shell-aliases.nix
│   │   │   ├── starship.nix
│   │   │   ├── tmux.nix
│   │   │   ├── zoxide.nix
│   │   │   └── zsh.nix
│   │   ├── walker.nix
│   │   └── waybar
│   │       ├── style.css
│   │       └── waybar.nix
│   ├── services
│   │   ├── audio.nix
│   │   ├── hypr
│   │   │   ├── hypridle.nix
│   │   │   └── hyprlock.nix
│   │   ├── sddm.nix
│   │   ├── snapshots.nix
│   │   ├── swaync
│   │   │   └── swaync.nix
│   │   └── tailscale.nix
│   └── toplevel
│       ├── bluetooth.nix
│       ├── boot.nix
│       ├── cachix.nix
│       ├── common-configuration.nix
│       ├── cosmic.nix
│       ├── env.nix
│       ├── gnome.nix
│       ├── guest.nix
│       ├── home-manager.nix
│       ├── home-packages.nix
│       ├── home.nix
│       ├── hyprland.nix
│       ├── kde.nix
│       ├── kernel.nix
│       ├── mime.nix
│       ├── net.nix
│       ├── nh.nix
│       ├── niri.nix
│       ├── nix.nix
│       ├── qt.nix
│       ├── stylix.nix
│       ├── timezone.nix
│       ├── user.nix
│       └── zram.nix
├── packages
│   └── utilities
│       └── krokiet
│           ├── czkawka-krokiet_logo.svg
│           └── krokiet.nix
├── README.md
├── rices
├── templates
│   └── dev-environments
│       └── language-specific
│           ├── c-cpp
│           ├── go
│           ├── haskell
│           ├── java
│           ├── jupyter
│           ├── latex
│           ├── nix
│           ├── node
│           ├── php
│           ├── python
│           ├── r
│           ├── rust
│           ├── shell
│           ├── swift
│           └── typst
└── users
    └── krit


102 directories, 160 files
```

