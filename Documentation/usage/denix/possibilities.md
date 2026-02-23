# Host Configuration Guide

- [Host Configuration Guide](#host-configuration-guide)
  - [Introduction](#introduction)
  - [Configuration Template](#configuration-template)
  - [Module enabled by default](#module-enabled-by-default)
    - [Module that can be disabled but are enabled by default](#module-that-can-be-disabled-but-are-enabled-by-default)
    - [Module that are always enabled](#module-that-are-always-enabled)
  - [Detailed Component Explanations](#detailed-component-explanations)
    - [Constants](#constants)
    - [Top-Level Modules](#top-level-modules)
    - [Desktop Environments \& Window Managers](#desktop-environments--window-managers)
    - [Custom Shells](#custom-shells)
    - [Command-Line Programs (`programs.`)](#command-line-programs-programs)
    - [Services (`services.`)](#services-services)
    - [Host-Specific Extensions (`full-host.services.`)](#host-specific-extensions-full-hostservices)



## Introduction

This document explains every possible programs/service that can be enabled using denix. It acts as a cookbook where you can see the possible recipes.
Critical warnings are included for specific modules that directly impact system functionality if disabled.

- When configuring a new host remember to add the `hardware-configuration.nix` to the excluded path in `flake.nix`
---

## Configuration Template


```nix
{ delib
, inputs
, pkgs
, ...
}:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  myBrowser = "firefox";
  myTerminal = "alacritty";
  myShell = "bash";
  myEditor = "nvim";
  myFileManager = "dolphin";
  myUserName = "krit";
  isCatppuccin = true;

  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    other = "5";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
  };

  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];

  smartLaunch =
    app: if builtins.elem app termApps then "${myTerminal} --class ${app} -e ${app}" else app;

  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "chromium" = "chromium-browser.desktop";
    "brave" = "brave-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "Nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";
in
delib.host {
  name = "template-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      constants = {
        hostname = "template-host";
        user = myUserName;
        gitUserName = myUserName;
        gitUserEmail = "${myUserName}@example.com";

        terminal = myTerminal;
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        monitors = [
          "eDP-1, 1920x1080@60, 0x0, 1"
        ];

        wallpapers = [
          {
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
            wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
          }
        ];

        theme = {
          polarity = "dark";
          base16Theme = "catppuccin-mocha";
          catppuccin = true;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "teal";
        };

        screenshots = "$HOME/Pictures/Screenshots";
        keyboardLayout = "us";
        keyboardVariant = "intl";

        weather = "London";
        useFahrenheit = false;
        nixImpure = false;

        timeZone = "Etc/UTC";
      };

      bluetooth.enable = true;
      cachix = {
        enable = true;
        push = false;
      };

      guest.enable = false;
      home-packages.enable = true;
      mime.enable = true;
      nh.enable = true;
      qt.enable = true;

      zram = {
        enable = true;
        zramPercent = 25;
      };

      stylix = {
        enable = true;
        targets = { alacritty.enable = !isCatppuccin; };
      };

      cosmic.enable = false;
      gnome.enable = false;
      hyprland.enable = true;
      kde.enable = false;
      niri.enable = false;

      programs.bat.enable = false;
      programs.eza.enable = false;
      programs.fzf.enable = true;

      programs.git = {
        enable = false;
        customGitIgnores = [ ];
      };

      programs.lazygit.enable = false;
      programs.shell-aliases.enable = true;
      programs.starship.enable = false;
      programs.tmux.enable = false;
      programs.walker.enable = true;

      programs.waybar = {
        enable = true;
        waybarLayout = {
          "format-en" = "🇺🇸-EN";
        };
        waybarWorkspaceIcons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          "6" = "";
          "7" = ":";
          "8" = ":";
          "9" = ":";
          "10" = ":";
          "magic" = ":";
        };
      };

      programs.zoxide.enable = true;

      programs.caelestia = {
        enable = false;
        enableOnHyprland = false;
      };

      programs.noctalia = {
        enable = false;
        enableOnHyprland = false;
        enableOnNiri = false;
      };

      programs.hyprland = {
        enable = true;
        execOnce = [
          "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
          "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
          "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
          "sleep 4 && uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
          "whatsapp-electron"
        ];
        monitorWorkspaces = [
          "1, monitor:DP-1"
          "2, monitor:DP-1"
          "3, monitor:DP-1"
          "4, monitor:DP-1"
          "5, monitor:DP-1"
          "6, monitor:DP-2"
          "7, monitor:DP-2"
          "8, monitor:DP-2"
          "9, monitor:DP-2"
          "10, monitor:DP-2"
        ];
        windowRules = [
          "workspace ${appWorkspaces.editor}, class:^(${myEditor})$"
          "workspace ${appWorkspaces.fileManager}, class:^(${myFileManager})$"
          "workspace ${appWorkspaces.terminal}, class:^(${myTerminal})$"
          "workspace ${appWorkspaces.editor} silent, class:^(code)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(org.kde.dolphin)$"
          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(chromium-browser)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(kitty)$"
          "workspace ${appWorkspaces.chat} silent, class:^(vesktop)$"
          "float, class:^(scratch-term)$"
          "center, class:^(scratch-term)$"
          "size 80% 80%, class:^(scratch-term)$"
          "workspace special:magic, class:^(scratch-term)$"
          "float, class:^(scratch-fs)$"
          "center, class:^(scratch-fs)$"
          "size 80% 80%, class:^(scratch-fs)$"
          "workspace special:magic, class:^(scratch-fs)$"
          "float, class:^(scratch-browser)$"
          "center, class:^(scratch-browser)$"
          "size 80% 80%, class:^(scratch-browser)$"
          "workspace special:magic, class:^(scratch-browser)$"
        ];
        extraBinds = [
          "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
        ];
      };

      programs.niri = {
        enable = false;
        execOnce = [
          "${myBrowser}"
          "${myEditor}"
          "${myFileManager}"
          "${myTerminal}"
        ];
      };

      programs.gnome = {
        enable = false;
        screenshots = "/home/krit/Pictures/Screenshots";
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
        ];
        extraBinds = [
          {
            name = "Launch Chromium";
            command = "chromium";
            binding = "<Super>y";
          }
        ];
      };

      programs.kde = {
        enable = false;
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
        ];
        extraBinds = {
          "launch-chromium" = {
            key = "Meta+Y";
            command = "chromium";
          };
        };
      };

      services.audio.enable = true;
      services.hyprlock.enable = false;
      services.sddm.enable = true;

      services.snapshots = {
        enable = false;
        retention = {
          hourly = "24";
          daily = "7";
          weekly = "4";
          monthly = "3";
          yearly = "2";
        };
      };

      services.tailscale.enable = false;
      services.hypridle = {
        enable = false;
        dimTimeout = 900;
        lockTimeout = 1800;
        screenOffTimeout = 3600;
      };

      services.swaync = {
        enable = false;
        customSettings = {
          "mute-protonvpn" = {
            state = "ignored";
            app-name = ".*Proton.*";
          };
        };
      };

      full-host.services.flatpak.enable = false;
      full-host.services.local-packages.enable = false;
    };
}

```

---

## Module enabled by default
### Module that can be disabled but are enabled by default
TODO: complete
### Module that are always enabled
TODO: complete

## Detailed Component Explanations

### Constants

The `constants` block acts as the central data bucket for the framework, distributing values dynamically to all other modules.

* **`hostname` & `user**`: Define the machine's hostname and the primary Unix user account.
* **`gitUserName` & `gitUserEmail**`: Global Git identity defaults.
* **`terminal`, `shell`, `browser`, `editor`, `fileManager**`: Defines the user's primary default applications. The smart-launch logic automatically handles terminal wrappers if terminal-based apps (like `nvim` or `yazi`) are selected.
* **`monitors`**: A list of output device configurations (resolution, position, scale) primarily consumed by Wayland compositors (Hyprland sintax but they are needed to apply the wallpaper logic to most modules).
* **`wallpapers`**: URL and SHA256 hashes of wallpapers dynamically fetched and applied across desktop environments and lock screens.
* **`theme`**: Master styling settings dictating `polarity` (dark/light), the core Base16 color scheme, and the exact Catppuccin flavor/accent if enabled.
* **`screenshots`**: Absolute default directory path for screen captures.
* **`keyboardLayout` & `keyboardVariant**`: Defines system-wide keyboard mapping and variant configurations.
* **`weather` & `useFahrenheit**`: Configures the location and temperature scale for dashboard and Waybar weather modules.
* **`nixImpure`**: A toggle to switch system rebuild commands between pure and impure modes.
* **`timeZone`**: System timezone mapping.

### Top-Level Modules

* **`bluetooth`**: Enables the system Bluetooth daemon and related utility packages.
* **`cachix`**: Configures Nix to pull from (and optionally push to) a specified binary cache resulting in much faster rebuild and evaluation.
* **`guest`**: Enable the guest user account.
* **`home-packages`**: Injects standard, everyday applications automatically based on the chosen core preferences (browser, terminal, etc.) and other one that may be needed to every host.
* **Warning:** Disabling this means the system does not automatically install the chosen browser, editor, file manager and terminal based on the host preferences.


* **`mime`**: Explicitly maps the defined default applications to file types across the system.
* **Warning:** Disabling this would cause the shortcuts that open "browser, editor, file manager" to fail and/or open with fallback given by the distro itself.


* **`nh`**: A fast, user-friendly wrapper for NixOS rebuild commands.
* **Warning:** Disabling this would cause most nix-related aliases build, flake check, and similar aliaes to fail (since they rely on nh being present).


* **`qt`**: Configures Qt application themes, platform integrations, and rendering engines.
* **Warning:** Disabling this would cause graphical inconsistencies.


* **`zram`**: Enables a compressed swap space in RAM to drastically improve system performance under memory pressure.
* **Warning:** Enabled because it's beneficial everywhere.


* **`stylix`**: Global theming engine that colors and styles almost every application automatically based on the constants.
* **Warning:** Disabling this would cause massive graphical inconsistencies regarding general theming, polarity and wallpaper



### Desktop Environments & Window Managers

* **`cosmic`**: The Rust-based COSMIC desktop environment built by System76.
* **`gnome`**: The GNOME desktop environment, with optional extra app pinning and keyboard shortcut configurations.
* **`hyprland`**: A highly customizable, dynamic tiling Wayland compositor. Includes optional extra window rules, workspace configurations, and scratchpad setups.
* **Warning:** Enabled to have at least one wm.


* **`kde`**: The KDE Plasma desktop environment. Includes optional extra app pinning and keyboard shortcut configurations.
* **`niri`**: A scrollable-tiling Wayland compositor.

### Custom Shells

* **`caelestia`**: A highly customizable visual shell/dashboard overlay designed for Hyprland.
* **`noctalia`**: A highly customizable visual shell environment supporting both Hyprland and Niri.

### Command-Line Programs (`programs.`)

* **`bat`**: A `cat` command alternative featuring syntax highlighting, line numbers, and Git integration.
* **`eza`**: A modern, colorful replacement for the standard `ls` command, featuring icons and Git status awareness.
* **`fzf`**: A highly efficient command-line fuzzy finder used extensively in shell aliases.
* **Warning:** Disabling this would cause some shell aliases to not work.


* **`git`**: The core version control integration and global user settings.
* **Warning:** Note git as a package is installed anyway (in `common-configuration.nix`); disabling this only means disabling the custom configuration such as setting the user identity and the global GitIgnores.


* **`lazygit`**: A terminal-based GUI application to simplify complex Git commands.
* **`shell-aliases`**: A centralized repository of command-line shortcuts deployed across bash, zsh, and fish.


* **`starship`**: A fast, deeply customizable prompt for any shell, themed dynamically.
* **`tmux`**: A terminal multiplexer for managing multiple sessions, windows, and panes within a single terminal instance.
* **`walker`**: A highly customizable, fast application launcher and clipboard manager for Wayland.
* **Warning:** Disabling this means missing an app launcher in hyprland/niri.


* **`waybar`**: A powerful, modular status bar for Wayland window managers, configured with workspaces and system tray integrations.
* **`zoxide`**: A smarter `cd` command that tracks your most frequently visited directories.
* **Warning:** Disabling this would cause some aliases to not work.



### Services (`services.`)

* **`audio`**: Configures the underlying sound server daemon (usually PipeWire) and audio management tools.
* **`hyprlock`**: A screen locker built specifically for the Hyprland ecosystem.
* **`sddm`**: The Simple Desktop Display Manager, providing the graphical login screen.
* **Warning:** Without this there would not be a display manager, forcing to use a tty.


* **`snapshots`**: A BTRFS snapshot retention automation system using Snapper to back up the file system on a timeline.
* **`tailscale`**: A zero-config mesh VPN service that builds secure networks between your devices.
* **`hypridle`**: An idle management daemon for Wayland that automatically dims, locks, and turns off displays after inactivity.
* **`swaync`**: A notification daemon and control center for Wayland compositors.

### Host-Specific Extensions (`full-host.services.`)

* **`flatpak`**: Enables the Flatpak package management framework for installing isolated applications.
* **`local-packages`**: A specific toggle to include custom packages defined purely for that particular machine host.
