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
├── flake.nix                                      # ❄️ Entry point: Inputs, hosts, and global variables
│
├── home-manager/                                  # 🏠 User-specific configuration (The "Rice")
│   │
│   ├── home.nix                                   # Main user entry point and directory setup
│   ├── home-packages.nix                          # List of user-only software
│   │
│   └── modules/                                   # Application-specific configurations
│       │
│       ├── cosmic/                                # cosmic-specific configuration
│       │   ├── cosmic-binds.nix                   # cosmic keyboard shortcuts
│       │   ├── default.nix                        # Cosmic redirector
│       │   └── cosmic-main.nix                    # Core Gnome rules
│       │
│       ├── gnome/                                 # gnome-specific configuration
│       │   ├── gnome-binds.nix                    # gnome keyboard shortcuts
│       │   ├── default.nix                        # Gnome redirector
│       │   └── gnome-main.nix                     # Core Gnome rules
│       │
│       ├── hyprland/                              # Hyprland-specific configuration
│       │   ├── hyprland-binds.nix                 # Keyboard shortcuts
│       │   ├── default.nix                        # Hyprland Redirector
│       │   ├── hyprland-hypridle.nix              # Idle daemon (auto-lock/sleep)
│       │   ├── hyprland-hyprlock.nix              # Lock screen styling
│       │   ├── hyprland-hyprpaper.nix             # Wallpaper daemon
│       │   └── hyprland-main.nix                  # Core Hyprland rules
│       │
│       ├── kde/                                   # KDE-specific configuration
│       │   ├── default.nix                        # KDE Redirector
│       │   ├── kde-desktop.nix                    # KDE Desktop configuration
│       │   ├── kde-files.nix                      # KDE Low-level files behaviour configuration
│       │   ├── kde-inputs.nix                     # KDE hardware (mouse and trackpad) configuration
│       │   ├── kde-krunner.nix                    # KDE Krunner configuration
│       │   ├── kde-kscreenlock.nix                # KDE screen locker configuration
│       │   ├── kde-main.nix                       # KDE Core rules
│       │   ├── kde-panels.nix                     # KDE taskbar configuration
│       │   └── kde-binds.nix                      # KDE keyboard shortcuts configuration
│       │
│       ├── swaync/                                # Notification Center
│       │   ├── default.nix                        # Notification logic & CSS injection
│       │   └── style.css                          # Custom CSS styling (ignored)
│       │
│       ├── waybar/                                # Status Bar
│       │   ├── default.nix                        # Layout & module definition
│       │   └── style.css                          # Custom CSS styling
│       │
│       ├── wofi/                                  # App Launcher
│       │   ├── default.nix                        # Logic & CSS injection
│       │   └── style.css                          # Manual CSS styling
│       │
│       ├── bat.nix                                # 'cat' clone settings
│       ├── core.nix                               # Module importer
│       ├── eza.nix                                # 'ls' clone settings
│       ├── git.nix                                # Git credentials & aliases
│       ├── lazygit.nix                            # Git TUI settings
│       ├── mime.nix                               # Default app configuration
│       ├── neovim.nix                             # Editor wrapper (uses dotfiles)
│       ├── qt.nix                                 # Manual QT/Kvantum theming logic
│       ├── starship.nix                           # Shell prompt customization
│       ├── stylix.nix                             # Global Base16 theme engine
│       ├── tmux.nix                               # Terminal Multiplexer
│       └── zsh.nix                                # Shell aliases & history
│
├── hosts/                                         # 🖥️ Host-specific overrides
│   │
│   └── <hostname>/                                # Contains hosts-specifics aspects
│       ├── host-modules/                          # Optional host-specific home-manager modules
│       │   └── default.nix                        # Importer for the home-manager host-specific modules
│       │
│       ├── configuration.nix                      # System-level hardware tweaks
│       ├── disko-config.nix                       # Disko configuration for partitioning with btrfs
│       ├── flatpak.nix                            # Applications installed through flatpak
│       ├── home.nix                               # Host-specific home directory configuration
│       ├── hardware-configuration.nix             # Host-specific hardware configuration
│       ├── local-packages.nix                     # Hosts-specific packages
│       ├── modules.nix                            # More in-depth home-manager modules configuration
│       └── variables.nix                          # Host-specific variables
│
├── nixos/                                         # ⚙️ System-wide Modules (Root)
│   └── modules/                                   # OS Components (Boot, Net, Users)
│       ├── audio.nix                              # Pipewire/PulseAudio
│       ├── bluetooth.nix                          # Bluetooth logic
│       ├── boot.nix                               # Bootloader (Systemd-boot)
│       ├── core.nix                               # Import all nixOS system modules
│       ├── cosmic.nix                             # System-level cosmic enablement
│       ├── env.nix                                # Global environment variables
│       ├── gnome.nix                              # System-level gnome enablement
│       ├── guest.nix                              # Handle the guest user
│       ├── home-manager.nix                       # HM integration hooks
│       ├── hyprland.nix                           # System-level Hyprland enablement
│       ├── KDE.nix                                # System-level KDE enablement
│       ├── kernel.nix                             # Kernel parameters
│       ├── mime.nix                               # Default app associations
│       ├── net.nix                                # NetworkManager & Hostname
│       ├── nh.nix                                 # Nix Helper tool config
│       ├── nix.nix                                # Nix Daemon settings
│       ├── sddm.nix                               # Login manager
│       ├── snapshots.nix                          # Snapshot settings
│       ├── tailscale.nix                          # Manage tailscale service
│       ├── timezone.nix                           # Locale & Time settings
│       ├── user.nix                               # User accounts & groups
│       └── zram.nix                               # Memory optimization
│
└── screenshots/                                   # Assets for README
```


