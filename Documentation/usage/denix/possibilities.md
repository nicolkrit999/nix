# Denix possible modules

- [Denix possible modules](#denix-possible-modules)
  - [Introduction](#introduction)
    - [Common Modules (NixOS + Darwin)](#common-modules-nixos--darwin)
      - [Top-Level](#top-level)
      - [Themes](#themes)
      - [Command-Line Programs (`programs.`)](#command-line-programs-programs)
    - [NixOS-Only Modules](#nixos-only-modules)
      - [System](#system)
      - [Desktop Environments \& Window Managers](#desktop-environments--window-managers)
      - [Custom Shells](#custom-shells)
      - [Programs (`programs.`)](#programs-programs)
      - [Services (`services.`)](#services-services)
      - [Host-Specific Extensions (`full-host.services.`)](#host-specific-extensions-full-hostservices)
    - [Darwin-Only Modules](#darwin-only-modules)



##   Introduction

This document explains every possible programs/service that can be enabled using denix. It acts as a cookbook where you can see the possible recipes.
Critical warnings are included for specific modules that directly impact system functionality if disabled.

- When configuring a new host remember to add the `hardware-configuration.nix` to the excluded path in `flake.nix`
---




### Common Modules (NixOS + Darwin)

These modules work on both NixOS and Darwin hosts.

#### Top-Level

* **`cachix`**: Configures Nix to pull from (and optionally push to) a specified binary cache, resulting in much faster rebuilds and evaluation.
* **`home-packages`**: Injects standard, everyday applications automatically based on the chosen core preferences (browser, terminal, editor, fileManager) and others that may be needed on every host.
* **Warning:** Disabling this means the system does not automatically install the chosen browser, editor, file manager, and terminal based on the host preferences.

* **`nh`**: A fast, user-friendly wrapper for NixOS/nix-darwin rebuild commands.
  * **Warning:** Disabling this would cause most nix-related aliases (`build`, `flake check`, and similar) to fail since they rely on `nh` being present.

* **`stylix`**: Global theming engine that colors and styles almost every application automatically based on the constants.
  * **Warning:** Disabling this would cause massive graphical inconsistencies regarding general theming, polarity, and wallpaper.

#### Themes

* **`themes.catppuccin`**: Imports the catppuccin-nix theming modules for both NixOS/Darwin system-level and home-manager, enabling Catppuccin palette integration across all supported applications.

#### Command-Line Programs (`programs.`)

* **`programs.bash`**: Configures the Bash shell with Hyprland socket fixes, custom `.bashrc` loading, and optional `tmux` autostart.
* **`programs.bat`**: A `cat` command alternative featuring syntax highlighting, line numbers, and Git integration.
* **`programs.claude-code`**: Sets up the Claude Code CLI tool with optional MCP secrets provisioning via sops-nix and required environment configuration.
* **`programs.comma`**: Enables the `comma` (`,`) tool from nix-index-database, allowing any Nix package to be run ad-hoc without installing it (` , command`).
* **`programs.eza`**: A modern, colorful replacement for the standard `ls` command, featuring icons and Git status awareness.
* **`programs.fish`**: Configures the Fish shell with alias/abbreviation setup and environment initialization.
* **`programs.fzf`**: A highly efficient command-line fuzzy finder used extensively in shell aliases.
* **Warning:** Disabling this would cause some shell aliases to not work.

* **`programs.git`**: The core version control integration and global user settings.
* **Warning:** Note that `git` as a package is installed anyway (in `common-configuration.nix`); disabling this only means disabling the custom configuration such as setting the user identity and global GitIgnores.

* **`programs.lazygit`**: A terminal-based GUI application to simplify complex Git commands.
* **`programs.shell-aliases`**: A centralized repository of command-line shortcuts deployed across bash, zsh, and fish.
* **`programs.starship`**: A fast, deeply customizable prompt for any shell, themed dynamically.
* **`programs.statix`**: Installs statix, a static analysis / linter for Nix code that catches common mistakes and anti-patterns.
* **`programs.television`**: Installs the `television` TUI fuzzy-finder with a Nix channel and an `ns` shell wrapper for interactive Nix package search.
* **`programs.tmux`**: A terminal multiplexer for managing multiple sessions, windows, and panes within a single terminal instance.
* **`programs.zoxide`**: A smarter `cd` command that tracks your most frequently visited directories.
* **Warning:** Disabling this would cause some aliases to not work.

* **`programs.zsh`**: Configures the Zsh shell with shell aliases and common initialization settings.

---

### NixOS-Only Modules

These modules are only available on NixOS hosts.

#### System

* **`bluetooth`**: Enables the system Bluetooth daemon and related utility packages.
* **`boot`**: Sets up the Plymouth boot splash screen and GRUB bootloader with UEFI support, OS prober, and multi-resolution graphics configuration.
* **`env`**: Exports system-wide environment variables (`BROWSER`, `TERMINAL`, `EDITOR`, `XDG_BIN_HOME`) derived from the host constants.
* **`guest`**: Enables a guest user account on the system.
* **`kernel`**: Selects the Zen kernel on x86_64 for desktop performance, and falls back to the latest standard kernel on other architectures (e.g., ARM).
* **`mime`**: Explicitly maps the defined default applications to file types across the system.
  * **Warning:** Disabling this would cause the shortcuts that open "browser, editor, file manager" to fail and/or open with the distro's fallback.

* **`net`**: Enables NetworkManager for network connectivity and installs `impala`, a TUI network monitoring tool.
* **`qt`**: Configures Qt application themes, platform integrations, and rendering engines.
  * **Warning:** Disabling this would cause graphical inconsistencies in Qt applications.

* **`timezone`**: Sets the system timezone from the `constants.timeZone` value (default: `Etc/UTC`).
* **`xdg-portal`**: Configures XDG desktop portals with DE-specific backends for screensharing and file picking (Hyprland, KDE, GNOME, COSMIC, and niri all have tailored configurations).
  * **Warning:** Disabling this would cause graphical inconsistencies as well as some apps not behaving correctly.
* **`zram`**: Enables a compressed swap space in RAM to drastically improve system performance under memory pressure.
  * **Warning:** Enabled because it is beneficial everywhere.

#### Desktop Environments & Window Managers

* **`programs.cosmic`**: The Rust-based COSMIC desktop environment built by System76.
* **`programs.gnome`**: The GNOME desktop environment, with optional extra app pinning and keyboard shortcut configurations.
* **`programs.hyprland`**: A highly customizable, dynamic tiling Wayland compositor. Includes monitor config, exec-on-start rules, workspace-to-monitor assignments, window rules, and optional extra keybinds.
  * **Warning:** Enabled to have at least one WM.

* **`programs.kde`**: The KDE Plasma desktop environment. Includes optional app pinning, keyboard shortcuts, panel layout, krunner config, screen locker, and input settings.
* **`programs.niri`**: A scrollable-tiling Wayland compositor with optional exec-on-start and keybind configurations.

#### Custom Shells

* **`programs.caelestia`**: A highly customizable visual shell/dashboard overlay designed for Hyprland, with QML2 import paths and environment setup.
* **`programs.noctalia`**: A highly customizable visual shell environment supporting both Hyprland and Niri, with conditional enablement per compositor.

#### Programs (`programs.`)

* **`programs.cava`**: Configures cava, a terminal audio spectrum visualizer, with stylix color integration.
* **`programs.nix-alien`**: Enables nix-alien for running unpatched Linux binaries in Nix via automatic FHS environment generation.
* **`programs.nix-ld`**: Enables Nix's dynamic linker (`nix-ld`) so pre-compiled binaries can run without manual patching.
* **`programs.nix-topology`**: Imports the nix-topology module for generating visual diagrams of the NixOS network/host architecture.
* **`programs.walker`**: Installs the Walker application launcher with optional Hyprland and Waybar integration.
* **Warning:** Disabling this means missing an app launcher in Hyprland/niri.

* **`programs.waybar`**: A powerful, modular status bar for Wayland window managers, configured with workspaces, workspace icons, keyboard layout display, and system tray integrations.

#### Services (`services.`)

* **`services.audio`**: Configures the PipeWire sound server and related audio management tools.
* **`services.auto-cpufreq`**: Enables the auto-cpufreq daemon, an automatic CPU speed and power optimizer that dynamically adjusts CPU governors and turbo based on battery state and system load. Mutually exclusive with TLP.
* **`services.hypridle`**: An idle management daemon for Wayland that automatically dims, locks, and turns off displays after configurable inactivity timeouts.
* **`services.hyprlock`**: A screen locker built specifically for the Hyprland ecosystem.
* **`services.impermanence`**: Configures an ephemeral root filesystem with a persistent `/persist` overlay for important directories and files (NetworkManager, SSH, Bluetooth, Tailscale, etc.).
* **`services.sddm-astronaut`**: Configures the SDDM login manager with the Astronaut theme (jake_the_dog variant).
  * **Warning (sddm):** Without a display manager there would be no graphical login, forcing use of a TTY.
  * Only enable one sddm at any moment
* **`services.sddm-pixie`**: Configures the SDDM login manager with the Pixie theme and customizable styling options.
  * **Warning (sddm):** Without a display manager there would be no graphical login, forcing use of a TTY.
  * Only enable one sddm at any moment

* **`services.snapshots`**: A BTRFS snapshot retention automation system using Snapper to back up the filesystem on a configurable timeline (hourly, daily, weekly, monthly, yearly).
* **`services.swaync`**: A notification daemon and control center for Wayland compositors, with optional per-app notification muting rules.
* **`services.tailscale`**: A zero-config mesh VPN service that builds secure networks between your devices.
* **`services.tlp`**: An advanced power management tool that optimizes battery life by configuring processor energy-performance policies, frequency scaling, and optional charging thresholds based on power source. Mutually exclusive with auto-cpufreq. ⚠️ Contains and enable `thermald` which is an intel-only setup. Set it as false if using an amd host

#### Host-Specific Extensions (`full-host.services.`)

* **`full-host.services.flatpak`**: Enables the Flatpak package management framework for installing isolated applications.
* **`full-host.services.local-packages`**: A specific toggle to include custom packages defined purely for that particular machine host.

---

### Darwin-Only Modules

These modules are active on Darwin (macOS/nix-darwin) hosts. Most are always-on infrastructure modules that handle platform integration and are not toggled by the user.

* **`common-configuration` (darwin)**: Core Darwin system defaults — sets hostname, enables Touch ID for sudo, configures macOS system preferences, and links system packages.
* **`home-packages` (darwin)**: Installs the host's chosen browser, terminal, editor, and file manager via home-manager packages on macOS, with a translation layer to map Nix-native names to Homebrew/macOS equivalents.
* **`nix` (darwin)**: Configures the Nix daemon settings (garbage collection, flakes, trusted users, substituters) for nix-darwin.
* **`stylix` (darwin)**: Darwin-specific Stylix theming engine — applies the base16 palette and fonts across supported macOS/home-manager applications.
* **`user` (darwin)**: Declares the primary user account for nix-darwin (uid, home directory, shell).
