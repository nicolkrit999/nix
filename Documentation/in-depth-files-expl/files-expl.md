- [~nixOS/flake.nix](#nixosflakenix)
  - [Key Concepts](#key-concepts)
    - [1. The "Two-Architecture" Build System](#1-the-two-architecture-build-system)
    - [2. Recursive Configuration with Denix](#2-recursive-configuration-with-denix)
    - [3. Unified Input Management](#3-unified-input-management)
  - [The Code](#the-code)
- [~nixOS/modules/toplevel/home.nix](#nixosmodulestoplevelhomenix)
  - [Key Concepts](#key-concepts-1)
    - [1. User Identity \& State Version](#1-user-identity--state-version)
    - [2. Modular Architecture](#2-modular-architecture)
    - [3. XDG Integration \& KDE Fixes](#3-xdg-integration--kde-fixes)
    - [4. Imperative Actions (Activation Scripts)](#4-imperative-actions-activation-scripts)
  - [The Code](#the-code-1)
- [~nixOS/modules/toplevel/home-packages.nix](#nixosmodulestoplevelhome-packagesnix)
  - [Key Concepts](#key-concepts-2)
    - [1. Dynamic Selection](#1-dynamic-selection)
    - [2. Global vs. Host-Specific](#2-global-vs-host-specific)
  - [The Code](#the-code-2)
- [~nixOS/modules/programs/de-wm/gnome/gnome-main.nix](#nixosmodulesprogramsde-wmgnomegnome-mainnix)
  - [Key Concepts](#key-concepts-3)
    - [1. Wallpaper Handling (Single Monitor Focus)](#1-wallpaper-handling-single-monitor-focus)
    - [2. Adaptive Theming (Polarity)](#2-adaptive-theming-polarity)
    - [3. Dconf Overrides](#3-dconf-overrides)
  - [The Code](#the-code-3)
- [~nixOS/modules/programs/de-wm/hyprland/hyprland-main.nix](#nixosmodulesprogramsde-wmhyprlandhyprland-mainnix)
  - [Key Concepts](#key-concepts-4)
    - [1. Dynamic Monitor Configuration](#1-dynamic-monitor-configuration)
    - [2. Theming Bridge (Catppuccin vs. Stylix)](#2-theming-bridge-catppuccin-vs-stylix)
    - [3. Environment \& Compatibility](#3-environment--compatibility)
    - [4. Smart Rules](#4-smart-rules)
  - [The Code](#the-code-4)
- [~nixOS/modules/programs/de-wm/kde/kde-main.nix](#nixosmodulesprogramsde-wmkdekde-mainnix)
  - [Key Concepts](#key-concepts-5)
    - [1. Multi-Monitor Wallpapers](#1-multi-monitor-wallpapers)
    - [2. Dynamic Theme Construction](#2-dynamic-theme-construction)
    - [3. Config Overrides](#3-config-overrides)
  - [The Code](#the-code-5)
- [~nixOS/modules/programs/waybar/waybar.nix](#nixosmodulesprogramswaybarwaybarnix)
  - [Key Concepts](#key-concepts-6)
    - [1. Hybrid Theming (CSS + Nix Variables)](#1-hybrid-theming-css--nix-variables)
    - [2. Host-Specific Customization](#2-host-specific-customization)
    - [3. Dynamic Weather Script](#3-dynamic-weather-script)
    - [4. Conditionals](#4-conditionals)
  - [The Code](#the-code-6)
- [~nixOS/modules/programs/walker.nix](#nixosmodulesprogramswalkernix)
  - [Key Concepts](#key-concepts-7)
    - [1. Stylix theming](#1-stylix-theming)
    - [2. Create some shortcuts](#2-create-some-shortcuts)
  - [The Code](#the-code-7)
- [~nixOS/home-manager/modules/qt.nix](#nixoshome-managermodulesqtnix)
  - [Key Concepts](#key-concepts-8)
    - [1. The "Magic" Fix: `QT_QPA_PLATFORMTHEME=kde`](#1-the-magic-fix-qt_qpa_platformthemekde)
    - [2. "Faking" the KDE Environment (`kdeglobals`)](#2-faking-the-kde-environment-kdeglobals)
    - [3. Dual Configuration (`qt5ct` as Backup)](#3-dual-configuration-qt5ct-as-backup)
  - [The Code](#the-code-8)
- [~nixOS/modules/toplevel/stylix.nix](#nixosmodulestoplevelstylixnix)
  - [Key Concepts](#key-concepts-9)
    - [1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)](#1-the-traffic-cop-strategy-catppuccin-vs-base16)
    - [2. The Qt/KDE Cohesion Strategy (Manual Hand-off)](#2-the-qtkde-cohesion-strategy-manual-hand-off)
      - [How the Cohesion Works:](#how-the-cohesion-works)
    - [3. Global Assets](#3-global-assets)
  - [The Code](#the-code-9)
- [~nixOS/modules/toplevel/common-configuration.nix](#nixosmodulestoplevelcommon-configurationnix)
  - [Key Concepts](#key-concepts-10)
    - [1. The "Survival Kit" (Universal Packages)](#1-the-survival-kit-universal-packages)
    - [2. Architecture Intelligence (x86 vs. ARM)](#2-architecture-intelligence-x86-vs-arm)
    - [3. Performance \& Responsiveness](#3-performance--responsiveness)
    - [4. Security Baseline](#4-security-baseline)
  - [The Code](#the-code-10)
- [~nixOS/modules/toplevel/boot.nix](#nixosmodulestoplevelbootnix)
  - [Key Concepts](#key-concepts-11)
    - [1. GRUB vs. systemd-boot](#1-grub-vs-systemd-boot)
    - [2. Dual Boot Support (`os-prober`)](#2-dual-boot-support-os-prober)
    - [3. UEFI Accessibility](#3-uefi-accessibility)
  - [The Code](#the-code-11)
- [~nixOS/modules/toplevel/env.nix](#nixosmodulestoplevelenvnix)
  - [Key Concepts](#key-concepts-12)
    - [1. Smart Editor Configuration](#1-smart-editor-configuration)
    - [2. Dynamic Defaults](#2-dynamic-defaults)
    - [3. Path Injection](#3-path-injection)
  - [The Code](#the-code-12)
- [~nixOS/nixos/modules/guest.nix](#nixosnixosmodulesguestnix)
  - [Key Concepts](#key-concepts-13)
    - [1. Ephemeral Home (`tmpfs`)](#1-ephemeral-home-tmpfs)
    - [2. Forced Desktop Environment (XFCE)](#2-forced-desktop-environment-xfce)
    - [3. Security Hardening](#3-security-hardening)
    - [4. User Warning](#4-user-warning)
  - [The Code](#the-code-13)
- [~nixOS/modules/toplevel/mime.nix](#nixosmodulestoplevelmimenix)
  - [Key Concepts](#key-concepts-14)
    - [1. Dynamic Associations](#1-dynamic-associations)
    - [2. Desktop File Translation (`mkDesktop`)](#2-desktop-file-translation-mkdesktop)
  - [The Code](#the-code-14)
- [~nixOS/modules/toplevel/nix.nix](#nixosmodulestoplevelnixnix)
  - [Key Concepts](#key-concepts-15)
    - [1. Enabling Flakes](#1-enabling-flakes)
    - [2. Binary Caching (Speed)](#2-binary-caching-speed)
    - [3. Automatic Garbage Collection](#3-automatic-garbage-collection)
  - [The Code](#the-code-15)
- [~nixOS/modules/services/sddm.nix](#nixosmodulesservicessddmnix)
  - [Key Concepts](#key-concepts-16)
    - [1. The "Astronaut" Theme](#1-the-astronaut-theme)
  - [The Code](#the-code-16)
- [~nixOS/modules/toplevel/user.nix](#nixosmodulestoplevelusernix)
  - [Key Concepts](#key-concepts-17)
    - [1. The "Safety Net" (Why configure groups twice?)](#1-the-safety-net-why-configure-groups-twice)
    - [2. Global Shell Enforcement](#2-global-shell-enforcement)
  - [The Code](#the-code-17)

# ~nixOS/flake.nix

The `flake.nix` file is the **brain** of the configuration. It is the entry point where Nix starts reading. Its job is not to configure the system (it doesn't set wallpapers or install packages directly), but to **orchestrate** the build process.

It performs three main tasks:

1. **Inputs:** Downloads necessary dependencies (NixOS sources, Home Manager, custom plugins).
2. **Logic:** Defines the blueprint using denix to know which folders include modules to load and which to exclude
3. **Architecture:** Define 2 supported architecture

---

## Key Concepts

### 1. The "Two-Architecture" Build System

The flake is designed to be truly cross-platform by supporting both **x86_64-linux** and **aarch64-linux** (ARM) architectures simultaneously.


**System Enumeration**: The `allSystems` variable explicitly defines these two supported architectures.



**Universal Formatting**: The `forAllSystems` helper ensures that maintenance tools, like the `nixpkgs-fmt` formatter, are available for both types of hardware.



**Cross-Architecture Derivations**: The system is configured to accept `aarch64-linux` derivations, allowing to manage ARM-based devices or builders from an x86 host.



### 2. Recursive Configuration with Denix

Instead of manually listing every file, it uses the **Denix** library to automatically discover and map your entire repository structure.


**Path Discovery**: Denix scans specific top-level directories—`hosts`, `modules`, `packages`, and `users`—to build the system tree.



**Evaluation Exclusions**: To avoid build error when the target folders contains non denix modules, for example specific files like `hardware-configuration.nix` and profile sub-directories are manually excluded from the standard recursive scan.


**Dual-Target Output**: The `mkConfigurations` function is called twice to generate both `nixosConfigurations` (system-level) and `homeConfigurations` (user-level) from the same source paths.



### 3. Unified Input Management
 
**Pinned Ecosystems**: Major styling and theme tools like **Stylix** and **Catppuccin** are pinned to specific release branches (e.g., `release-25.11`) to ensure stability across updates.



**Addon Integration**: It integrates the `rycee/nur-expressions` specifically to provide automated Firefox/LibreWolf extensions.


**Input Following**: To avoid "dependency hell" and bloated builds, most external inputs are forced to follow the `nixpkgs` version.

---

## The Code

```nix
{
  description = "NixOS configuration with multiple hosts, denix, cachix, sops";

  outputs =
    { denix, nixpkgs, ... }@inputs:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      mkConfigurations =
        moduleSystem:
        denix.lib.configurations {
          inherit moduleSystem;
          homeManagerUser = "krit";

          extensions = with denix.lib.extensions; [
            args
            (base.withConfig {
              args.enable = true;
              rices.enable = false;
            })
          ];

          paths = [
            ./hosts
            ./modules
            ./packages
            ./users
          ];

          exclude = [
            ./users/krit/dev-environments
            ./users/krit/modules/programs/gui-programs/librewolf/profiles

        
            ./hosts/nixos-desktop/hardware-configuration.nix
            ./hosts/nixos-laptop/hardware-configuration.nix
            ./hosts/template-host-minimal/hardware-configuration.nix
            ./hosts/template-host-full/hardware-configuration.nix

            ./hosts/template-host-minimal/disko-config.nix
            ./hosts/template-host-full/disko-config.nix

          ];

          specialArgs = { inherit inputs moduleSystem; };
        };
    in
    {
      nixosConfigurations = mkConfigurations "nixos";
      homeConfigurations = mkConfigurations "home";
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Needed to get firefox addons from nur
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official catppuccin-nix flake
    catppuccin = {
      url = "github:catppuccin/nix/release-25.11"; # Changed from "github:catppuccin/nix" to pin to it and avoid the "services.displayManager.generic" does not exist evalution warning after a "nix flake update" done on february, 13, 2026
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-community plasma manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Official quickshell flake
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official caelestia flake
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official noctalia flake
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official sops-nix flake
    nix-sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

}

```

# ~nixOS/modules/toplevel/home.nix

The `home.nix` file is the **root configuration** for Home Manager. While `configuration.nix` manages the _system_ (drivers, bootloader, root users), `home.nix` manages the _user_ (dotfiles, themes, user-specific packages).

It serves as the foundation upon which your personal environment is built.

---

## Key Concepts

### 1. User Identity & State Version

This file establishes who the user is. It receives variables like `user` and `homeStateVersion`to dynamically set the username and home directory path 

### 2. Modular Architecture

Instead of listing every single program here, `home.nix` uses an **imports** list.


- `home-packages.nix`: Loads the list of user-installed software. These are software that are available to all hosts.

### 3. XDG Integration & KDE Fixes

This section handles the crucial bridge between your declarative config and how Linux actually finds and launches applications.

- **File Associations (`mimeApps`):**
  `xdg.mimeApps.enable = true;` is the switch that activates your `mime.nix` rules. Without this, your preferred default apps (like opening PDFs with Zathura or images with Gwenview) would be ignored.
- **The KDE Launcher & Dolphin Fix (`applications.menu`):**
  KDE applications (Dolphin, KRunner) rely on a specific file, `applications.menu`, to build their internal database of installed programs. In pure Window Managers like Hyprland, this file is often missing.
- **The Problem:** If missing, `kbuildsycoca6` (KDE's cache builder) fails. Dolphin won't know that "Gwenview" exists, so it keeps asking you "Which app should I use?" and fails to generate thumbnails.
- **The Fix:** We manually create a standard XDG menu file. This tricks KDE into correctly scanning your system, fixing file associations, thumbnails, and ensuring apps appear correctly in menus.

### 4. Imperative Actions (Activation Scripts)

Nix is declarative (defining _what_ should exist), but sometimes we need to perform actions _when_ the configuration switches.

- **Cleanup:** We use activation scripts to forcibly remove conflicting config files (like old GTK settings) that might prevent Home Manager from writing new symlinks.
- **Creation:** We ensure essential directories (like `Pictures/screenshots`) exist before applications try to use them.

---

## The Code

```nix
{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "home";

  nixos.always =
    { myconfig, ... }:
    {
      home-manager.users.${myconfig.constants.user} =
        { config, ... }:
        {
          home = {
            username = myconfig.constants.user;
            homeDirectory = "/home/${myconfig.constants.user}";
            stateVersion = myconfig.constants.homeStateVersion or "25.11";
            sessionPath = [ "$HOME/.local/bin" ];
          };

          programs.home-manager.enable = true;

          xdg = {
            enable = true;
            mimeApps.enable = true;
            userDirs = {
              enable = true;
              createDirectories = true;
            };

            configFile."menus/applications.menu".text = ''
              <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
              "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
              <Menu>
                <Name>Applications</Name>
                <DefaultAppDirs/>
                <DefaultDirectoryDirs/>
                <Include>
                  <Category>System</Category>
                  <Category>Utility</Category>
                </Include>
              </Menu>
            '';

            dataFile."dbus-1/services/org.kde.kwalletd5.service".text = ''
              [D-BUS Service]
              Name=org.kde.kwalletd5
              Exec=${pkgs.coreutils}/bin/false
            '';
            dataFile."dbus-1/services/org.kde.kwalletd.service".text = ''
              [D-BUS Service]
              Name=org.kde.kwalletd
              Exec=${pkgs.coreutils}/bin/false
            '';
          };
        
          home.file.".local/bin/init-gnome-keyring.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              pkill -f kwallet || true
              sleep 0.5
              eval $(${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
              export SSH_AUTH_SOCK
              export GNOME_KEYRING_CONTROL
              export GNOME_KEYRING_PID
              ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
              ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK GNOME_KEYRING_CONTROL GNOME_KEYRING_PID

              if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
                 if command -v hyprctl >/dev/null; then
                    hyprctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
                    hyprctl setenv GNOME_KEYRING_CONTROL "$GNOME_KEYRING_CONTROL"
                    hyprctl setenv GNOME_KEYRING_PID "$GNOME_KEYRING_PID"
                 fi
              fi
            '';
          };

        
          home.file.".config/plasma-workspace/env/99-init-keyring.sh".source =
            config.lib.file.mkOutOfStoreSymlink "/home/${myconfig.constants.user}/.local/bin/init-gnome-keyring.sh";

          home.activation = {
            removeExistingConfigs = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
              rm -f "$HOME/.config/autostart/gnome-keyring-force.desktop"
              rm -f "$HOME/.gtkrc-2.0"
              rm -f "$HOME/.config/gtk-3.0/settings.ini"
              rm -f "$HOME/.config/gtk-3.0/gtk.css"
              rm -f "$HOME/.config/gtk-4.0/settings.ini"
              rm -f "$HOME/.config/gtk-4.0/gtk.css"
              rm -f "$HOME/.config/dolphinrc"
              rm -f "$HOME/.config/kdeglobals"
              rm -f "$HOME/.local/share/applications/mimeapps.list"
            '';
            createEssentialDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "${myconfig.constants.screenshots}"
            '';

            updateKDECache = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if command -v kbuildsycoca6 >/dev/null; then
                kbuildsycoca6 --noincremental || true
              fi
            '';
          };
        };
    };
}

```


---

# ~nixOS/modules/toplevel/home-packages.nix

This file defines the **Global Software List** that is installed on _every_ machine you own. It combines your personal preferences (defined in variables) with a static list of essential system utilities required for your configuration to function.

---

## Key Concepts

### 1. Dynamic Selection

Instead of hardcoding "firefox" or "neovim", this module intelligently installs the specific applications you selected in `variables.nix` (`term`, `browser`, `fileManager`, `editor`).

- **How it works:** It looks up the package name in the Nixpkgs database.
- **Safety Fallbacks:** If you mistype a name or leave a variable empty, it automatically installs a "safe" default (e.g., `kitty`, `google-chrome`, `dolphin`, `vscode`) so you are never left without a working system.

### 2. Global vs. Host-Specific

- **Edit this file** if you want an application (like `ripgrep` or `htop`) to be available on **all** your computers (desktop, laptop, server).
- **Do NOT edit this file** for machine-specific apps (e.g., install `steam` or `lutris`) if you don't want that package to be installed in all your hosts.
  - The host specific packages should be installed in one of those 2 location inside your specific host folder:
    - `home.nix`: These packages are installed only in the hosts machine but can be configured as a module inside home-manager
    - `local-packages.nix`: These packages are installed only for that host and can not be configured as a home-manager module


## The Code

```nix
# Install home-manager related packages for every host
# Not enabling it breaks the logic that automatically install the terminal, browser, file manager and editor depending on host-specific constants
{
  delib,
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      # 🔄 TRANSLATION LAYER
      translatedEditor =
        let
          e = myconfig.constants.editor or "vscode";
        in
        if e == "nvim" then "neovim" else e;

      # 🛡️ SAFE FALLBACKS
      fallbackTerm = pkgs.alacritty;
      fallbackBrowser = pkgs.brave;
      fallbackFileManager = pkgs.kdePackages.dolphin;
      fallbackEditor = pkgs.vscode;

      # 🔍 PACKAGE LOOKUP
      getPkg =
        name: fallback:
        if builtins.hasAttr name pkgs then
          pkgs.${name}
        else if builtins.hasAttr name pkgs.kdePackages then
          pkgs.kdePackages.${name}
        else
          fallback;

      termName = myconfig.constants.terminal or "alacritty";
      myTermPkg = getPkg termName fallbackTerm;

      browserName = myconfig.constants.browser or "brave";
      myBrowserPkg = getPkg browserName fallbackBrowser;

      fileManagerName = myconfig.constants.fileManager or "dolphin";
      myFileManagerPkg = getPkg fileManagerName fallbackFileManager;

      editorName = translatedEditor;
      myEditorPkg = getPkg editorName fallbackEditor;
    in
    {

      environment.systemPackages =
        let
          # ✅ This checks if a NixOS module is already handling the program
          # If the host has enabled a module in this way then it's not installed from this file to avoid evaluations errors due to duplicates
          isModuleEnabled = name: lib.attrByPath [ "programs" name "enable" ] false config;
        in
        (lib.optional (!isModuleEnabled termName) myTermPkg)
        ++ (lib.optional (!isModuleEnabled browserName) myBrowserPkg)
        ++ (lib.optional (!isModuleEnabled fileManagerName) myFileManagerPkg)
        ++ (lib.optional (!isModuleEnabled editorName) myEditorPkg)
        ++ (with pkgs; [
          cliphist
        ])
        ++ (with pkgs.kdePackages; [
          gwenview
        ])
        ++ (with pkgs-unstable; [ ]);
    };

}

```

# ~nixOS/modules/programs/de-wm/gnome/gnome-main.nix

This file manages the GNOME Desktop Environment settings. Since GNOME stores most of its configuration in a binary database called `dconf`, it is not possible to edit a simple text file like `hyprland.conf`. Instead, Home Manager's `dconf.settings` module is used to inject these settings directly into the database.

---

## Key Concepts

### 1. Wallpaper Handling (Single Monitor Focus)

Unlike Hyprland (which assigns specific wallpapers to specific monitor ports), GNOME handles wallpapers globally.

### 2. Adaptive Theming (Polarity)

This module respects the `polarity` variable ("dark" or "light") defined in your host configuration.

- It automatically switches the GNOME system interface (`prefer-dark` vs `prefer-light`).
- It selects the appropriate icon theme variant (`Papirus-Dark` vs `Papirus-Light`).

### 3. Dconf Overrides

We use `dconf.settings` to declaratively set preferences that you would normally change in "GNOME Settings" or "GNOME Tweaks".

- **Window Buttons:** We explicitly add Minimize and Maximize buttons, which modern GNOME often hides by default.

---

## The Code

```nix
{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.gnome";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      screenshots = strOption "$HOME/Pictures/Screenshots";
      pinnedApps = listOfOption str [ ];
      extraBinds = listOfOption attrs [ ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
      wallpaperPath = pkgs.fetchurl {
        url = fallbackWp.wallpaperURL;
        sha256 = fallbackWp.wallpaperSHA256;
      };
      colorScheme = if myconfig.constants.theme.polarity == "dark" then "prefer-dark" else "prefer-light";
      iconThemeName =
        if myconfig.constants.theme.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";

      rawPinnedApps = cfg.pinnedApps;
      hasPins = builtins.length rawPinnedApps > 0;
    in
    {
      home.packages =
        (lib.optionals myconfig.constants.theme.catppuccin [
          (pkgs.catppuccin-gtk.override {
            accents = [ myconfig.constants.theme.catppuccinAccent ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = myconfig.constants.theme.catppuccinFlavor or "mocha";
          })
        ])
        ++ [
          pkgs.papirus-icon-theme
          pkgs.hydrapaper
        ];

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = lib.mkForce colorScheme;
          icon-theme = iconThemeName;
        };

        "org/gnome/desktop/background" = {
          picture-uri = "file://${wallpaperPath}";
          picture-uri-dark = "file://${wallpaperPath}";
          picture-options = lib.mkForce "zoom";
        };

        "org/gnome/desktop/screensaver" = {
          picture-uri = "file://${wallpaperPath}";
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };

        "org/gnome/shell" = lib.mkIf hasPins { favorite-apps = rawPinnedApps; };
      };
    };
}

```

# ~nixOS/modules/programs/de-wm/hyprland/hyprland-main.nix

This file contains the core configuration for **Hyprland**, a dynamic tiling Wayland compositor. Unlike traditional window managers where you edit a `.conf` file in `~/.config/hypr`, this file generates that configuration dynamically based on your system variables.

It handles window placement, monitors, theming, and startup applications.

---

## Key Concepts

### 1. Dynamic Monitor Configuration

Instead of hardcoding monitor ports (which change between laptops and desktops), this module pulls the `monitors` constants from the host

- **Logic:** It iterates through your defined monitors and adds a "fallback" rule (`preferred, auto, 1`) at the end. This ensures that if you plug in a new, undefined monitor, it still works immediately.

### 2. Theming Bridge (Catppuccin vs. Stylix)

This file acts as a bridge between your chosen theme and Hyprland's settings.

- **If Catppuccin is enabled:** It uses the official Catppuccin module variables (`$accent`, `$overlay0`) for borders.
- **If Catppuccin is disabled:** It extracts colors directly from **Stylix** (`config.lib.stylix.colors.base0D`) to match your Base16 theme perfectly.

### 3. Environment & Compatibility

Wayland is newer than X11, so some apps need "convincing" to run correctly. We define a list of **Environment Variables** (`env`) to force apps like VS Code (Electron) and Dolphin (QT) to run in native Wayland mode instead of using the slower XWayland compatibility layer.

### 4. Smart Rules

- **Smart Gaps:** The config includes logic to remove gaps and borders when only one window is on the screen, maximizing screen real estate.
- **Workspace Binding:** It imports `hyprlandWorkspaces` from your host-specific `modules.nix`. This allows the workspaces numbers and binding to be host-specific

---

## The Code

```nix
{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.hyprland";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      monitors = listOfOption str [ ",preferred, auto,1" ];
      execOnce = listOfOption str [ ];
      monitorWorkspaces = listOfOption str [ ];
      windowRules = listOfOption str [ ];
      extraBinds = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      term = myconfig.constants.terminal or "alacritty";
      rawFm = myconfig.constants.fileManager or "dolphin";
      rawEd = myconfig.constants.editor or "vscode";

      # List of known terminal-based apps. Add more as needed
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

      smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
      smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;
    in

    {
      # ----------------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      catppuccin.hyprland.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprland.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprland.accent = myconfig.constants.theme.catppuccinAccent or "mauve";
      # ----------------------------------------------------------------------------

      home.packages = with pkgs; [
        grimblast # Screenshot tool
        hyprpaper # Wallpaper manager
        hyprpicker # Color picker
        imv # Image viewer (referenced in window rules)
        mpv # Video player (referenced in window rules)
        brightnessctl # Screen brightness control
        pavucontrol # Volume control
        playerctl # Media player control
        showmethekey # Keypress visualizer
        wl-clipboard # Wayland clipboard utilities
        xdg-desktop-portal-hyprland # Required for screen sharing
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };

        settings = {
          env =
            let
              firstMonitor =
                if builtins.length cfg.monitors > 0 then
                  builtins.head cfg.monitors
                else
                  "";
              monitorParts = lib.splitString "," firstMonitor;
              rawScale = if (builtins.length monitorParts) >= 4 then builtins.elemAt monitorParts 3 else "1";
              gdkScale = if rawScale != "1" && rawScale != "1.0" then "2" else "1";
            in
            [
              "NIXOS_OZONE_WL,1" # Enables Wayland support in NixOS-built Electron apps
              "QT_QPA_PLATFORM,wayland;xcb" # Tells Qt apps: "Try Wayland first. If that fails, use X11 (xcb)".
              "GDK_BACKEND,wayland,x11,*" # Tells GTK apps: "Try Wayland first. If that fails, use X11".
              "SDL_VIDEODRIVER,wayland" # Forces SDL games to run on Wayland (improves performance/scaling).
              "CLUTTER_BACKEND,wayland" # Forces Clutter apps to use Wayland.
              "_JAVA_AWT_WM_NONREPARENTING,1" # Fixes Java GUI apps (IntelliJ, Minecraft Launcher) on Wayland.
              "GDK_SCALE,${gdkScale}" # Sets GTK scaling based on first monitor's scale factor.

              # DESKTOP SESSION IDENTITY
              "XDG_CURRENT_DESKTOP,Hyprland" # Tells portals (screen sharing) that you are using Hyprland.
              "XDG_SESSION_TYPE,wayland" # Generic flag telling the session it is Wayland-based.
              "XDG_SESSION_DESKTOP,Hyprland" # Used by some session managers to identify the desktop.

              # SYSTEM PATHS
              "XDG_SCREENSHOTS_DIR,${myconfig.constants.screenshots}" # Tells tools where to save screenshots by default.
            ];

          monitor = cfg.monitors;

          "$Mod" = "SUPER";
          "$terminal" = term;
          "$browser" = myconfig.constants.browser or "firefox";
          "$fileManager" = smartFm;
          "$editor" = smartEd;
          "$menu" = "walker";
          "$shellMenu" =
            if myconfig.programs.caelestia.enableOnHyprland or false then
              "caelestiaQS"
            else if myconfig.programs.noctalia.enableOnHyprland or false then
              "noctalia-shell ipc call toggleAppLauncher"
            else
              "walker";

          exec-once = [
            "${pkgs.bash}/bin/bash $HOME/.local/bin/init-gnome-keyring.sh"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            "pkill ibus-daemon"
          ]
          ++ cfg.execOnce;

          general = {
            gaps_in = 0; # Gaps between windows
            gaps_out = 0; # Gaps between windows and monitor edge
            border_size = 5; # Thickness of window borders

            "col.active_border" =
              if myconfig.constants.theme.catppuccin then
                "$accent"
              else
                "rgb(${config.lib.stylix.colors.base0D})";

            "col.inactive_border" =
              if myconfig.constants.theme.catppuccin then
                "$overlay0"
              else
                "rgb(${config.lib.stylix.colors.base03})";

            resize_on_border = true;

            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 0;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            shadow = {
              enabled = false;
            };

            blur = {
              enabled = false;
            };
          };

          animations = {
            enabled = true;
          };

          input = {
            kb_layout = myconfig.constants.keyboardLayout or "us";
            kb_variant = myconfig.constants.keyboardVariant or "";
            kb_options = "grp:ctrl_alt_toggle"; # Ctrl+Alt to switch layout
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          master = {
            new_status = "slave";
            new_on_top = true;
            mfact = 0.5;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          xwayland = {
            force_zero_scaling = true;
          };

          windowrulev2 = [
            # Smart Borders: No border if only 1 window is on screen
            "bordersize 0, floating:0, onworkspace:w[t1]"

            #ShowMeTheKey  fixes. ShowMetheKey is a GTK app for displaying keypresses on screen.
            "float,class:(mpv)|(imv)|(showmethekey-gtk)" # Float media viewers and ShowMeTheKey
            "move 990 60,size 900 170,pin,noinitialfocus,class:(showmethekey-gtk)" # Position ShowMeTheKey
            "noborder,nofocus,class:(showmethekey-gtk)" # No border for ShowMeTheKey

            # Ueberzug fix for image previews
            "float, class:^(ueberzugpp_layer)$"
            "noanim, class:^(ueberzugpp_layer)$"
            "noshadow, class:^(ueberzugpp_layer)$"
            "noblur, class:^(ueberzugpp_layer)$"
            "noinitialfocus, class:^(ueberzugpp_layer)$"

            # Gwenview fix for opening images
            "float, class:^(org.kde.gwenview)$"
            "center, class:^(org.kde.gwenview)$"
            "size 80% 80%, class:^(org.kde.gwenview)$"

            # FILE DIALOGS (Firefox, Upload, Download, Save As) ---
            "float, title:^(Open File)(.*)$"
            "float, title:^(Select a File)(.*)$"
            "float, title:^(Choose wallpaper)(.*)$"
            "float, title:^(Open Folder)(.*)$"
            "float, title:^(Save As)(.*)$"
            "float, title:^(Library)(.*)$"
            "float, title:^(File Upload)(.*)$"
            "float, title:^(Save File)(.*)$"
            "float, title:^(Enter name of file)(.*)$"

            # Center and resize ALL the titles listed above
            "center, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"
            "size 50% 50%, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"

            "float, class:^(xdg-desktop-portal-gtk)$"
            "center, class:^(xdg-desktop-portal-gtk)$"
            "size 50% 50%, class:^(xdg-desktop-portal-gtk)$"

            # Prevent Auto-Maximize & Focus Stealing ---
            "suppressevent maximize, class:.*"
            "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

            # XWayland Video Bridge ---
            "opacity 0.0 override, class:^(xwaylandvideobridge)$"
            "noanim, class:^(xwaylandvideobridge)$"
            "noinitialfocus, class:^(xwaylandvideobridge)$"
            "maxsize 1 1, class:^(xwaylandvideobridge)$"
            "noblur, class:^(xwaylandvideobridge)$"
            "nofocus, class:^(xwaylandvideobridge)$"
          ]
          ++ cfg.windowRules;

          workspace = [
            "w[tv1], gapsout:0, gapsin:0" # No gaps if only 1 window is visible
            "f[1], gapsout:0, gapsin:0" # No gaps if window is fullscreen
          ]
          ++ (cfg.monitorWorkspaces or [ ]);
        };
      };
    };
}

```

# ~nixOS/modules/programs/de-wm/kde/kde-main.nix

This file configures **KDE Plasma 6** using the community-driven `plasma-manager` module. Unlike GNOME (which uses `dconf`), KDE configuration is split across many different text files. `plasma-manager` abstracts this complexity, allowing us to configure the desktop declaratively.

---

## Key Concepts

### 1. Multi-Monitor Wallpapers

KDE Plasma handles wallpapers differently than GNOME. It supports distinct wallpapers for distinct monitors out of the box.

- **Logic:** We pass the **entire list** of wallpapers from the `wallpaper` block in the host file
- **Behavior:** `plasma-manager` automatically assigns the first wallpaper to the first monitor, the second to the second, and so on.

### 2. Dynamic Theme Construction

KDE themes often require specific naming conventions (e.g., "CatppuccinMochaSky").

- **If Catppuccin is Enabled:** We construct the theme name dynamically by combining the flavor and accent (capitalizing the first letter of each). We also switch the widget style to `kvantum` for better styling support.
- **If Catppuccin is Disabled:** We fall back to the standard "Breeze" themes (Dark or Light) based on the `polarity` variable.

### 3. Config Overrides

We use `overrideConfig = true` to ensure that our declarative settings take precedence over any manual changes made via the GUI. This ensures the system always boots into the correct state, even if settings were messed up previously.

---

## The Code

```nix
{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "programs.kde";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      extraBinds = attrsOption { };
      mice = listOfOption attrs [ ];
      touchpads = listOfOption attrs [ ];
      pinnedApps = listOfOption str [ ];
    };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      wallpaperPaths = builtins.map (w: "${pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; }}") myconfig.constants.wallpapers;


      capitalize =
        s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

      theme =
        if myconfig.constants.theme.catppuccin then
          "Catppuccin${capitalize myconfig.constants.theme.catppuccinFlavor}${capitalize myconfig.constants.theme.catppuccinAccent}"
        else if myconfig.constants.theme.polarity == "dark" then
          "BreezeDark"
        else
          "BreezeLight";

      lookAndFeel =
        if myconfig.constants.theme.polarity == "dark" then
          "org.kde.breezedark.desktop"
        else
          "org.kde.breeze.desktop";
      cursorTheme = config.stylix.cursor.name;
    in
    {
      xdg.configFile."autostart/ibus-daemon.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Kill IBus Daemon
        Exec=pkill ibus-daemon
        Hidden=false
        StartupNotify=false
        X-KDE-autostart-phase=1
      '';

      programs.plasma = {
        enable = true;
        overrideConfig = lib.mkForce true;

        workspace = {
          clickItemTo = "select"; # Require double-click to open files (Windows-style)

          colorScheme = theme;
          lookAndFeel = lookAndFeel;
          cursor.theme = cursorTheme;
          wallpaper = wallpaperPaths;
        };
      };

    };
}
```

# ~nixOS/modules/programs/waybar/waybar.nix

This file configures **Waybar**, the status bar used in the Hyprland desktop environment. Unlike standard configurations that use static config files, this module builds the bar dynamically, allowing it to adapt to your theme, location, and host-specific preferences automatically.

---

## Key Concepts

### 1. Hybrid Theming (CSS + Nix Variables)

Waybar is styled using CSS. To allow switching between themes (like Nord, Dracula, or Catppuccin) without rewriting the CSS file every time, we inject Nix variables directly into the stylesheet.

**Catppuccin Mode:** If Catppuccin is enabled, we rely on the official module for most colors and only define the `@accent` variable based on your selected accent color.

- **Base16 Mode (Fallback):** If Catppuccin is disabled, we manually map generic Base16 hex codes (e.g., `base08`, `base0D`) to readable CSS variable names (e.g., `@red`, `@blue`). This ensures the bar looks correct regardless of which generic theme you choose.

### 2. Host-Specific Customization

This module consumes the custom variables passed from the host effectively "personalizing" the bar for the specific machine it is running on.

**`waybarWorkspaceIcons`:** Replaces standard workspace numbers (1, 2, 3) with custom icons (e.g., Terminal, Browser) defined for that specific host.

**`waybarLayoutFlags`:** Replaces the text layout identifier (e.g., "en", "it") with an emoji flag (e.g., "🇺🇸", "🇮🇹").

### 3. Dynamic Weather Script

Instead of a hardcoded weather widget, we define a `custom/weather` module. It uses the `weather` constant construct a `curl` command. This fetches live weather data from `wttr.in` and displays the condition icon and temperature.

### 4. Conditionals

The waybar is enabled/disabled depending on if `noctalia/caelestia` are used and it adapt to the workspace differences between `niri` and `hyprland`

---

## The Code

This code is my personal one, but it may be change heavily based on your preferences

```nix
{ delib
, lib
, config
, ...
}:
delib.module {
  name = "programs.waybar";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
      waybarWorkspaceIcons = attrsOption { };
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      c = config.lib.stylix.colors.withHashtag;
      cssVariables = ''
        @define-color base00 ${c.base00};
        @define-color base01 ${c.base01};
        @define-color base02 ${c.base02};
        @define-color base03 ${c.base03};
        @define-color base04 ${c.base04};
        @define-color base05 ${c.base05};
        @define-color base06 ${c.base06};
        @define-color base07 ${c.base07};
        @define-color base08 ${c.base08};
        @define-color base09 ${c.base09};
        @define-color base0A ${c.base0A};
        @define-color base0B ${c.base0B};
        @define-color base0C ${c.base0C};
        @define-color base0D ${c.base0D};
        @define-color base0E ${c.base0E};
        @define-color base0F ${c.base0F};
      '';

      cssContent = builtins.readFile ./style.css;
      # 1. hyprland logic: show waybar if no custom shell is set
      hyprlandWaybar =
        (parent.hyprland.enable or false)
        && !((parent.caelestia.enableOnHyprland or false) || (parent.noctalia.enableOnHyprland or false));

      niriWaybar = (parent.niri.enable or false) && !(parent.noctalia.enableOnNiri or false);

      isWaybarNeeded = hyprlandWaybar || niriWaybar;
    in
    lib.mkIf isWaybarNeeded {

      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
        };
        style = lib.mkAfter ''
          ${cssVariables}
          ${cssContent}
        '';

        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 40;

            modules-left = [
              "hyprland/workspaces"
              "niri/workspaces"
            ];

            modules-center = [
              "hyprland/window"
              "niri/window"
            ];

            modules-right = [
              "hyprland/language"
              "niri/language"
              "custom/weather"
              "pulseaudio"
              "battery"
              "clock"
              "tray"
            ];

            # Workspaces Icon and layout
            # A user may define host-specific icons (optional) in myconfig.constants.waybarWorkspaceIcons
            "hyprland/workspaces" = {
              disable-scroll = true;
              show-special = true;
              special-visible-only = true;
              all-outputs = false;
              format = "{name} {icon}";
              format-icons = cfg.waybarWorkspaceIcons;
            };

            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                active = "";
                default = "";
              };
            };

            "niri/window" = {
              format = "{}";
              separate-outputs = true;
            };

            # Languages flags and/or text
            # A user may define host-specific layout text (optional) in myconfig.constants.waybarLayout
            "hyprland/language" = {
              min-length = 5;
              tooltip = true;
              on-click = "hyprctl switchxkblayout all next";
            }
            // cfg.waybarLayout;

            "niri/language" = {
              format = "{}";
              on-click = "niri msg action switch-layout-next";
            }

            // cfg.waybarLayout;

            "custom/weather" = {
              format = "<span color='${c.base0C}'>${myconfig.constants.weather or "London"}:</span> {} ";

              exec =
                let
                  weatherLoc = myconfig.constants.weather or "London";
                in
                "curl -s 'wttr.in/${weatherLoc}?format=%c%t' | sed 's/ //'";

              interval = 300;
              class = "weather";

              on-click = ''xdg-open "https://wttr.in/${myconfig.constants.weather or "London"}"'';
            };

            "pulseaudio" = {
              format = "<span color='${c.base0D}'>{icon}</span> {volume}%";
              format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}% ";
              format-muted = "<span color='${c.base08}'></span> Muted";
              format-icons = {
                "headphones" = "";
                "handsfree" = "";
                "headset" = "";
                "phone" = "";
                "portable" = "";
                "car" = "";
                "default" = [
                  ""
                  ""
                ];
              };
              on-click = "pavucontrol";
            };

            "battery" = {
              states = {
                warning = 20;
                critical = 5;
              };
              format = "<span color='${c.base0A}'>{icon}</span> {capacity}%";
              format-charging = "<span color='${c.base0B}'></span> {capacity}%";
              format-alt = "{time} <span color='${c.base0A}'>{icon}</span>";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
            };

            "clock" = {
              format = "{:%A, %B %d at %I:%M %p}"; # Click Format: Full Day Name, Month, Date... When the module is clicked it switches between formats
              format-alt = "{:%m/%d/%Y - %I:%M %p}"; # Standard Format: MM/DD/YYYY - HH:MM AM/PM
              tooltip-format = "<tt><small>{calendar}</small></tt>"; # Tooltip Format: Small calendar in tooltip
              calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
              };
            };

            "tray" = {
              icon-size = 20;
              spacing = 8;
            };
          };
        };
      };

      systemd.user.services.waybar = {
        Unit.PartOf = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
        Unit.After = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
        Install.WantedBy = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
      };
    };
}

```

# ~nixOS/modules/programs/walker.nix

This file configures **walker**, the application launcher.

---

## Key Concepts

### 1. Stylix theming
- Uses the base16 theme to manually set a theme

### 2. Create some shortcuts
- Create shortcuts for some actions like clipboard manager and emojii

---

## The Code

```nix
{ delib
, inputs
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.walker";
  options = delib.singleEnableOption true;


  home.ifEnabled =
    { parent
    , ...
    }:
    let
      hyprlandWantsWaybar =
        (parent.hyprland.enable or false)
        && !(parent.caelestia.enableOnHyprland or false)
        && !(parent.noctalia.enableOnHyprland or false);

      niriWantsWaybar = (parent.niri.enable or false) && !(parent.noctalia.enableOnNiri or false);

      # If neither WM wants it (because they use custom shells), turn Waybar off
      shouldRunWaybar = hyprlandWantsWaybar || niriWantsWaybar;

    in
    {
      programs.waybar.enable = shouldRunWaybar;

      programs.waybar.systemd.enable = shouldRunWaybar;

      imports = [ inputs.walker.homeManagerModules.default ];

      home.packages = with pkgs; [
        xdg-utils
      ];

      programs.walker = {
        enable = true;
        runAsService = true;

        config = {
          theme = "default";
          force_keyboard_focus = true;
          close_when_open = true;

          keybinds = {
            close = [ "Escape" ];
            page_down = [
              "ctrl d"
              "Page_Down"
            ];
            page_up = [
              "ctrl u"
              "Page_Up"
            ];
            resume_last_query = [ "ctrl r" ];
            accept_type = [ "ctrl ;" ];
          };

          builtins.emojis = {
            enable = true;
            name = "emojis";
            icon = "face-smile";
            placeholder = "Emojis";
            switcher_only = true;
            history = true;
            typeahead = false;
            exec = "wl-copy";
            show_unqualified = true;
            prefix = ".";
          };

          ui = {
            fullscreen = true;
            width = 1600;
            height = 1200;
            anchors = {
              top = true;
              bottom = true;
              left = true;
              right = true;
            };
          };

          list.max_results = 50;
          providers = {
            clipboard.max_results = 50;
            websearch.prefix = "@";
            finder.prefix = "/";
            commands.prefix = ":";
          };
        };

        themes.default = {
          style = with config.lib.stylix.colors.withHashtag; ''
            /* DYNAMIC BASE16 MAPPING */
            @define-color window_bg_color ${base00};
            @define-color accent_bg_color ${base0D};
            @define-color theme_fg_color  ${base05};
            @define-color error_bg_color  ${base08};
            @define-color error_fg_color  ${base00};

            * {
              all: unset;
              font-family: 'JetBrainsMono Nerd Font', monospace;
            }

            popover {
              background: lighter(@window_bg_color);
              border: 1px solid darker(@accent_bg_color);
              border-radius: 18px;
              padding: 10px;
            }

            .normal-icons {
              -gtk-icon-size: 16px;
            }

            .large-icons {
              -gtk-icon-size: 32px;
            }

            scrollbar {
              opacity: 0;
            }

            .box-wrapper {
              box-shadow:
                0 19px 38px rgba(0, 0, 0, 0.3),
                0 15px 12px rgba(0, 0, 0, 0.22);
              background: @window_bg_color;
              padding: 20px;
              border-radius: 20px;
              border: 1px solid darker(@accent_bg_color);
            }

            .preview-box,
            .elephant-hint,
            .placeholder {
              color: @theme_fg_color;
            }

            .box {
            }

            .search-container {
              border-radius: 10px;
            }

            .input placeholder {
              opacity: 0.5;
            }

            .input selection {
              background: lighter(lighter(lighter(@window_bg_color)));
            }

            .input {
              caret-color: @theme_fg_color;
              background: lighter(@window_bg_color);
              padding: 10px;
              color: @theme_fg_color;
            }

            .input:focus,
            .input:active {
            }

            .content-container {
            }

            .placeholder {
            }

            .scroll {
            }

            .list {
              color: @theme_fg_color;
            }

            child {
            }

            .item-box {
              border-radius: 10px;
              padding: 10px;
            }

            .item-quick-activation {
              background: alpha(@accent_bg_color, 0.25);
              border-radius: 5px;
              padding: 10px;
            }

            /* child:hover .item-box, */
            child:selected .item-box {
              background: alpha(@accent_bg_color, 0.25);
            }

            .item-text-box {
            }

            .item-subtext {
              font-size: 12px;
              opacity: 0.5;
            }

            .providerlist .item-subtext {
              font-size: unset;
              opacity: 0.75;
            }

            .item-image-text {
              font-size: 28px;
            }

            .preview {
              border: 1px solid alpha(@accent_bg_color, 0.25);
              /* padding: 10px; */
              border-radius: 10px;
              color: @theme_fg_color;
            }

            #clipboard label,
            #clipboard textview,
            #clipboard #text {
              background-color: lighter(@window_bg_color);
              color: @theme_fg_color;
              margin: 10px;
              padding: 10px;
              border-radius: 10px;
            }

            .calc .item-text {
              font-size: 24px;
            }

            .calc .item-subtext {
            }

            .symbols .item-image {
              font-size: 24px;
            }

            .todo.done .item-text-box {
              opacity: 0.25;
            }

            .todo.urgent {
              font-size: 24px;
            }

            .todo.active {
              font-weight: bold;
            }

            .bluetooth.disconnected {
              opacity: 0.5;
            }

            .preview .large-icons {
              -gtk-icon-size: 64px;
            }

            .keybinds {
              padding-top: 10px;
              border-top: 1px solid lighter(@window_bg_color);
              font-size: 12px;
              color: @theme_fg_color;
            }

            .global-keybinds {
            }

            .item-keybinds {
            }

            .keybind {
            }

            .keybind-button {
              opacity: 0.5;
            }

            .keybind-button:hover {
              opacity: 0.75;
              cursor: pointer;
            }

            .keybind-bind {
              text-transform: lowercase;
              opacity: 0.35;
            }

            .keybind-label {
              padding: 2px 4px;
              border-radius: 4px;
              border: 1px solid @theme_fg_color;
            }

            .error {
              padding: 10px;
              background: @error_bg_color;
              color: @error_fg_color;
            }

            :not(.calc).current {
              font-style: italic;
            }

            .preview-content.archlinuxpkgs {
              font-family: monospace;
            }
          '';
        };
      };
    };
}
```

---

# ~nixOS/home-manager/modules/qt.nix

This file manages the look and feel of **Qt applications** (like Dolphin, VLC, OBS, KeepassXC).

It aims for a **native KDE Plasma look** (using the **Breeze** style) even when running on Hyprland.

---

## Key Concepts

### 1. The "Magic" Fix: `QT_QPA_PLATFORMTHEME=kde`

In your `hyprland-main.nix`, you set the environment variable `QT_QPA_PLATFORMTHEME=kde`. This is the single most important setting for Qt apps on Hyprland.

- **(`kde`):** By setting the platform to `kde`, we tell Qt apps: _"Act as if you are running inside a full KDE Plasma session."_

**Why it fixes the problem:** When Qt thinks it is in KDE, it loads the `plasma-integration` plugin (which you install in this file ). This plugin is much smarter than `qt5ct`. It automatically handles:

- Correct file dialogs (using the portal).
- Icon theme association.
- System color schemes.
- **Crucially:** It allows the **Breeze style** to render 100% correctly, looking exactly as it would on a Plasma desktop.

### 2. "Faking" the KDE Environment (`kdeglobals`)

Since you are running Hyprland, you don't actually have the KDE settings daemon running. For the `kde` platform theme to work, it needs to find the configuration files it _expects_ to see in a real Plasma session.

**The Activation Script:** This module includes a `home.activation` script. It runs every time you rebuild your system.

- **What it does:** It uses `kwriteconfig6` to manually write a standard KDE configuration file (`~/.config/kdeglobals`).
- **The Result:** It injects your chosen color scheme (`BreezeDark` or `BreezeLight`) and icon theme (`Papirus`) directly into this file. When a Qt app launches, it reads this "fake" file and applies your colors perfectly.

### 3. Dual Configuration (`qt5ct` as Backup)

Although the `kde` platform theme is the priority, this file still generates configuration files for `qt5ct` and `qt6ct`.

- **Consistency:** It ensures that even if an app ignores the `kde` platform override and falls back to generic settings, it is still forced to use the `breeze` style and your specified color scheme paths.

**Color Linking:** It links the official KDE Breeze color files from the nix store into `~/.local/share/color-schemes` so both the KDE integration and generic Qt tools can find them.

---

## The Code

```nix
{
  delib,
  pkgs,
  lib,
  inputs,
  ...
}:
delib.module {
  name = "qt";

  # Not enabling this module causes qt apps theming issue, especially regarding the polarity
  options = delib.singleEnableOption true;

  home.ifEnabled =
    {
      myconfig,
      ...
    }:
    let
      # Determine which environments are active
      hyprEnabled = myconfig.programs.hyprland.enable or false;
      kdeEnabled = myconfig.programs.kde.enable or false;
      useKdePlatformTheme = hyprEnabled || kdeEnabled;

      # Theme Variables
      isDark = (myconfig.constants.theme.polarity or "dark") == "dark";
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
      flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      capitalize =
        s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

      # Dynamically calculate the precise color scheme name
      kdeColorScheme =
        if isCatppuccin then
          "Catppuccin${capitalize flavor}${capitalize accent}"
        else if isDark then
          "BreezeDark"
        else
          "BreezeLight";

      iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";

      # Use kvantum engine for Catppuccin, otherwise stick to standard Breeze
      widgetStyle = if isCatppuccin then "kvantum" else "Breeze";
    in
    {
      # Ensures WMs like Niri and Cosmic correctly theme Qt apps even without KDE running
      home.sessionVariables = {
        QT_QPA_PLATFORMTHEME = if useKdePlatformTheme then "kde" else "qt5ct";
      };

      home.packages =
        (with pkgs; [
          libsForQt5.qt5ct
          kdePackages.qt6ct
          papirus-icon-theme
        ])
        ++ (with pkgs; [ kdePackages.breeze ])
        # Ensure Catppuccin assets exist even if KDE is completely disabled in flake.nix
        ++ lib.optionals isCatppuccin (
          with pkgs;
          [
            catppuccin-kde
            catppuccin-kvantum
          ]
        )
        ++ lib.optionals useKdePlatformTheme (
          with pkgs;
          [
            kdePackages.plasma-integration
            kdePackages.kconfig
            libsForQt5.kconfig
          ]
        );

      # QT5CT / QT6CT CONFIGURATION (Used by Niri, Cosmic, Gnome)
      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=${widgetStyle}
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt6ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=${widgetStyle}
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt5ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      # Symlink the standard Breeze colors so Qt5ct/Qt6ct can find them
      xdg.dataFile."color-schemes/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."color-schemes/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
      xdg.dataFile."qt6ct/colors/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."qt6ct/colors/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
      xdg.dataFile."qt5ct/colors/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."qt5ct/colors/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";

      xdg.configFile."Kvantum/kvantum.kvconfig" = lib.mkIf isCatppuccin {
        text = ''
          [General]
          theme=catppuccin-${flavor}-${accent}
        '';
      };

      # KDEGLOBALS ACTIVATION SCRIPT (Used by Hyprland and KDE)
      # Forcefully aligns the KDE engine with our calculated values on every rebuild
      home.activation.kdeglobalsFromPolarity = lib.mkIf useKdePlatformTheme (
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons      --key Theme       "${iconThemeName}"  || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group KDE        --key widgetStyle "${widgetStyle}"    || true

          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group Icons      --key Theme       "${iconThemeName}"  || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group KDE        --key widgetStyle "${widgetStyle}"    || true
        ''
      );
    };
}
```

---

# ~nixOS/modules/toplevel/stylix.nix

This file configures **Stylix**, the central theming engine for the system. Stylix's job is to take a single "Base16" color scheme (or an image) and automatically inject it into _every_ application on your system (Shell, Editor, Browser, Desktop).

However, because we also support the official **Catppuccin** modules and require stable Qt behavior, this file acts as a **"Traffic Cop"**. It intelligently decides _who_ gets to theme _what_.

## Key Concepts

### 1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)

We want the best of both worlds:

- **If Catppuccin is Enabled:** We want the official Catppuccin modules (which are hand-tuned and often look better than generic generated themes) to handle applications like Hyprland, Alacritty, and Bat.
- **If Catppuccin is Disabled:** We want Stylix to automatically generate a theme for _everything_ based on the `base16Theme` variable (e.g., Dracula, Gruvbox, Nord).

We achieve this using the `!catppuccin` logic.

- `hyprland.enable = !catppuccin;` → "Only let Stylix theme Hyprland if Catppuccin is false."

### 2. The Qt/KDE Cohesion Strategy (Manual Hand-off)

You will notice that **`kde.enable`** and **`qt.enable`** are explicitly set to **`false`**. This is a deliberate "Separation of Powers" between `stylix.nix` and `qt.nix`.

- **The Problem:** Stylix attempts to force generic Base16 colors onto Qt applications (using `qt5ct`). On KDE Plasma, this conflicts with the desktop's native engine, often causing login loops or crashes. On Hyprland, it often results in broken icons or unreadable text.
- **The Solution (The Hand-off):** We tell Stylix to ignore Qt entirely. Instead, we delegate Qt theming to our custom **`modules/qt.nix`**.

#### How the Cohesion Works:

Even though they are separate files, they stay synchronized via the global **`myconfig.constants.polarity`** variable:

1. **Stylix (GTK & Others):** Reads `myconfig.constants.polarity` (Dark/Light) and generates the appropriate GTK theme and wallpaper.
2. **`qt.nix` (Qt & KDE):** Reads the same `myconfig.constants.polarity` variable.

- If `dark`: It forces the native **Breeze Dark** theme and **Papirus-Dark** icons.
- If `light`: It forces **Breeze Light** and **Papirus-Light**.

3. **Result:** Your GTK apps (themed by Stylix) and Qt apps (handled by `qt.nix`) always share the same Dark/Light mode, ensuring a consistent system look without the instability of forcing Stylix upon Qt.

### 3. Global Assets

Regardless of which theme engine we use for specific apps, Stylix always manages the **universal** assets to ensure consistency:

- **Wallpaper:** Sets the background image for the system.
- **Fonts:** Enforces `JetBrainsMono Nerd Font` everywhere.
- **Cursor:** Enforces the `DMZ-Black` cursor.

---

## The Code

```nix
{ delib
, pkgs
, lib
, inputs
, ...
}:
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };

  nixos.always =
    { ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];
    };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
    in
    {
      stylix = {
        enable = true;
        polarity = myconfig.constants.theme.polarity or "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme or "catppuccin-mocha"
        }.yaml";
        image = pkgs.fetchurl {
          url = fallbackWp.wallpaperURL;
          sha256 = fallbackWp.wallpaperSHA256;
        };

        cursor = {
          name = "DMZ-Black";
          size = 24;
          package = pkgs.vanilla-dmz;
        };
        fonts = {
          emoji = {
            name = "Noto Color Emoji";
            package = pkgs.noto-fonts-color-emoji;
          };
          monospace = {
            name = "JetBrainsMono Nerd Font";
            package = pkgs.nerd-fonts.jetbrains-mono;
          };
          sansSerif = {
            name = "Noto Sans";
            package = pkgs.noto-fonts;
          };
          serif = {
            name = "Noto Serif";
            package = pkgs.noto-fonts;
          };
          sizes = {
            terminal = 13;
            applications = 11;
          };
        };
      };
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;

      hyprlandEnabled = myconfig.programs.hyprland.enable or false;
      caelestiaEnabled = myconfig.programs.caelestia.enableOnHyprland or false;
      noctaliaEnabled = myconfig.programs.noctalia.enableOnHyprland or false;

      useHyprpaper = hyprlandEnabled && !caelestiaEnabled && !noctaliaEnabled;
    in
    {
      stylix.targets = {
        neovim.enable = false;
        wofi.enable = false;
        waybar.enable = false;
        hyprpaper.enable = lib.mkForce (!isCatppuccin && useHyprpaper);
        kde.enable = false;
        qt.enable = false;
        gnome.enable = myconfig.programs.gnome.enable or false;

        hyprland.enable = !isCatppuccin;
        hyprlock.enable = !isCatppuccin;
        gtk.enable = !isCatppuccin;
        swaync.enable = !isCatppuccin;
        bat.enable = !isCatppuccin;
        lazygit.enable = !isCatppuccin;
        tmux.enable = !isCatppuccin;
        starship.enable = !isCatppuccin;
      }
      // cfg.targets;

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then "prefer-dark" else "prefer-light";
      };

      home.sessionVariables = lib.mkIf isCatppuccin {
        GTK_THEME = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
          myconfig.constants.theme.catppuccinAccent or "mauve"
        }-standard+rimless,black";
        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkIf isCatppuccin {
        enable = true;
        theme = {
          package = pkgs.catppuccin-gtk.override {
            accents = [ (myconfig.constants.theme.catppuccinAccent or "mauve") ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = myconfig.constants.theme.catppuccinFlavor or "mocha";
          };
          name = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
            myconfig.constants.theme.catppuccinAccent or "mauve"
          }-standard+rimless,black";
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
        gtk4.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
      };
    };
}
```

# ~nixOS/modules/toplevel/common-configuration.nix

This file serves as the **universal baseline** for every machine in your infrastructure (desktops, laptops, etc.). It ensures that regardless of the specific hardware, every host starts with the same core tools, security policies, and performance tweaks.

---

## Key Concepts

### 1. The "Survival Kit" (Universal Packages)

It installs packages needed for every host to make this os work

### 2. Architecture Intelligence (x86 vs. ARM)

The file is smart enough to adapt based on the CPU architecture, preventing build errors on incompatible hardware.

**x86_64 Only:** It installs `gpu-screen-recorder` and sets up its root security wrappers _only_ if the system is an Intel/AMD machine.

**ARM (Laptops):** It silently skips these packages, ensuring your MacBook or ARM laptop builds successfully without trying to compile incompatible software.

### 3. Performance & Responsiveness

It applies global tweaks to make the system feel snappier:

- **System76 Scheduler:** Prioritizes the app you are currently using (foreground) for smoother performance.

- **Fast Boot:** Disables the "wait for network" service, which significantly speeds up startup times.

- **Power Management:** Enables modern daemons (`upower`, `power-profiles-daemon`) needed for battery reporting and UI integrations.

### 4. Security Baseline

It establishes the default security posture for the OS:

- **Polkit Rules:** Automatically approves specific safe actions (like realtime audio processing) for admin users to reduce annoying password prompts.

- **Privilege Wrappers:** Sets up security wrappers (like `cap_sys_admin` for screen recording) needed for specific tools to function without compromising the whole system.

---

## The Code

```nix
{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "common-configuration";

  nixos.always =
    { myconfig
    , ...
    }:
    let
      currentShell = myconfig.constants.shell or "zsh";

      shellPkg =
        if currentShell == "fish" then
          pkgs.fish
        else if currentShell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      # ---------------------------------------------------------
      # 🖥️ HOST IDENTITY
      # ---------------------------------------------------------
      networking.hostName = myconfig.constants.hostname;
      networking.networkmanager.enable = true;
      system.stateVersion = myconfig.constants.stateVersion or "25.11";

      # ---------------------------------------------------------
      # 🌍 LOCALE & TIME
      # ---------------------------------------------------------
      time.timeZone = myconfig.constants.timeZone or "Etc/UTC";

      # Keyboard Layout
      services.xserver.xkb = {
        layout = myconfig.constants.keyboardLayout or "us";
        variant = myconfig.constants.keyboardVariant or "";
      };
      console.useXkbConfig = true;

      # ---------------------------------------------------------
      # 🛠️ NIX SETTINGS
      # ---------------------------------------------------------
      nix.settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        extra-platforms = [ "aarch64-linux" ]; # Accept aarch64-linux derivations
      };

      # Gpu screen recorder overlay due to missing ARM support in the main package
      # TODO: check if it can be improved/if needed here or in another place
      nixpkgs.overlays = [
        (final: prev: {
          gpu-screen-recorder =
            if prev.stdenv.hostPlatform.system == "aarch64-linux" then
              prev.runCommand "gpu-screen-recorder-dummy" { } ''
                mkdir -p $out/bin
                echo 'echo "GPU Screen Recorder is not supported on ARM"' > $out/bin/gpu-screen-recorder
                echo 'echo "Not supported"' > $out/bin/gsr-kms-server
                chmod +x $out/bin/*
              ''
            else
              prev.gpu-screen-recorder;
        })
      ];

      # Allow unfree packages globally (needed for drivers, code, etc.)
      nixpkgs.config.allowUnfree = true;

      # ---------------------------------------------------------
      # 📦 SYSTEM PACKAGES
      # ---------------------------------------------------------
      environment.systemPackages =
        with pkgs;
        [
          # --- CLI UTILITIES ---
          dix # Nix diff viewer
          git # Version control
          nixfmt # Nix formatter
          nix-prefetch-scripts # Tools to get hashes for nix derivations (used in every shell modules)
          wget # Downloader
          curl # Downloader

          # --- SYSTEM TOOLS ---
          foot # Tiny, zero-config terminal (Rescue tool)
          gsettings-desktop-schemas # Global theme settings
          libnotify # Library for desktop notifications (used by most de/wm modules)
          polkit_gnome # Authentication agent, forced in every de/wm
          seahorse # GNOME key and password manager
          sops # Secret management
          shellPkg # The selected shell package (bash, zsh, or fish)
          xdg-desktop-portal-gtk # GTK portal backend for file pickers

          # --- GRAPHICS & GUI SUPPORT ---
          gpu-screen-recorder # For recording/caelestia
          gtk3 # Standard GUI toolkit
          libsForQt5.qt5.qtwayland # Qt5 Wayland bridge
          kdePackages.qtwayland # Qt6 Wayland bridge
        ]
        ++ (with pkgs.kdePackages; [
          gwenview # Default image viewer as defined in mime.nix
        ])

        ++ (with pkgs-unstable; [ ]);

      # ---------------------------------------------------------
      # 🎨 FONTS
      # ---------------------------------------------------------
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono # Primary monospace font (coding/terminal)
        nerd-fonts.symbols-only # Icon fallback
        noto-fonts # "No Tofu" standard
        dejavu_fonts # Core Linux fallback
        noto-fonts-lgc-plus # Extended European/Greek/Cyrillic
        noto-fonts-color-emoji # Color emojis
        noto-fonts-cjk-sans # Asian language support (Chinese/Japanese/Korean)
        texlivePackages.hebrew-fonts # Hebrew support
        font-awesome # System icons (Waybar/Bar)
        powerline-fonts # Shell prompt glyphs
        powerline-symbols # Terminal font glyphs
      ];
      fonts.fontconfig.enable = true;

      # ---------------------------------------------------------
      # 🛡️ SECURITY & WRAPPERS
      # ---------------------------------------------------------
      security.rtkit.enable = true;
      services.openssh.enable = true;

      # Wrappers for GPU Screen Recorder (needed for Caelestia/Recording)
      # TODO: check if it can be improved/if needed here or in another place
      security.wrappers = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
        gpu-screen-recorder = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_admin+ep";
          source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
        };
        gsr-kms-server = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_admin+ep";
          source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
        };
      };

      # Polkit Rules: Realtime Audio & GPU Recorder Permissions
      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            // Auto-approve realtime audio requests
            if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
                action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
              return polkit.Result.YES;
            }
            // Auto-approve gpu-screen-recorder running as root
            if (action.id == "org.freedesktop.policykit.exec" &&
                action.lookup("program") &&
                action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
              return polkit.Result.YES;
            }
          }
        });
      '';

      # Keyrings & Wallets
      # Globally enable GNOME Keyring
      services.gnome.gnome-keyring.enable = true;

      # Disable KWallet to avoid conflicts with GNOME Keyring
      # TODO: check if this really work. IF not must be improved to avoid conflicts when both gnome and kde are enabled
      security.pam.services.login.enableGnomeKeyring = true;
      security.pam.services.sddm.enableGnomeKeyring = true;
      security.pam.services.login.enableKwallet = lib.mkForce false;
      security.pam.services.kde.enableKwallet = lib.mkForce false;
      security.pam.services.sddm.enableKwallet = lib.mkForce false;

      # ---------------------------------------------------------
      # 🐚 SHELLS & ENVIRONMENT
      # ---------------------------------------------------------
      programs.zsh.enable = currentShell == "zsh";
      programs.fish.enable = currentShell == "fish";

      i18n.inputMethod.enabled = lib.mkForce null;
      environment.variables.GTK_IM_MODULE = lib.mkForce "";
      environment.variables.QT_IM_MODULE = lib.mkForce "";
      environment.variables.XMODIFIERS = lib.mkForce "";

      # -----------------------------------------------------
      # 🎨 GLOBAL THEME VARIABLES
      # -----------------------------------------------------
      environment.variables.GTK_APPLICATION_PREFER_DARK_THEME =
        if myconfig.constants.theme.polarity == "dark" then "1" else "0";

      # -----------------------------------------------------
      # ⚡ SYSTEM TWEAKS
      # -----------------------------------------------------
      # Reduce shutdown wait time for stuck services
      systemd.settings.Manager = {
        DefaultTimeoutStopSec = "10s";
      };

      # Enable home-manager backup files extension
      home-manager.backupFileExtension = lib.mkForce "hm-backup";

    };
}
```

# ~nixOS/modules/toplevel/boot.nix

This file handles the **Bootloader configuration**. It determines what you see when you first turn on your computer and how the operating system loads.

While NixOS defaults to `systemd-boot` for modern UEFI systems, this module explicitly switches to **GRUB**.

---

## Key Concepts

### 1. GRUB vs. systemd-boot

By default, NixOS uses `systemd-boot` because it is simple and fast. However, we force it off (`lib.mkForce false`) and enable **GRUB** instead.

- **Why?** GRUB is generally better at detecting other operating systems (Dual Booting) and offers more customization options for themes and visual styles.

### 2. Dual Boot Support (`os-prober`)

We enable `useOSProber = true`. This tells GRUB to scan your hard drives for other operating systems (like Windows or another Linux distro) and automatically add them to the boot menu. This is essential for dual-boot setups.

### 3. UEFI Accessibility

We add a custom menu entry called **"UEFI Firmware Settings"**.

- **The Benefit:** This allows you to reboot directly into your BIOS/UEFI settings from the boot menu, without needing to spam a certain key on the keyboard.

---

## The Code

```nix
{ delib
, lib
, ...
}:
delib.module {
  name = "boot";

  nixos.always = {
    boot.loader = {
      timeout = 30;
      efi.canTouchEfiVariables = true;

      systemd-boot.enable = lib.mkForce false;

      grub = {
        enable = lib.mkForce true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        extraGrubInstallArgs = [ "--bootloader-id=nixos" ]; 

        extraEntries = ''
          menuentry "UEFI Firmware Settings" {
            fwsetup
          }
        '';
      };
    };
  };
}

```

---

# ~nixOS/modules/toplevel/env.nix

This file defines global **Environment Variables** that are available to all users and processes on the system. It ensures that your preferred tools (like your terminal, browser, and editor) are recognized as defaults by the operating system and other applications.

---

## Key Concepts

### 1. Smart Editor Configuration

Setting the `EDITOR` variable isn't always straightforward. Some GUI editors (like VS Code or Kate) return control to the terminal immediately, which breaks tools like `git commit` that need to wait for you to save and close the file.

- **The Solution:** We use a **Translation Layer** (`editorFlags`) that automatically appends the necessary flags to your chosen editor:
- `vscode` → `code --wait`
- `kate` → `kate --block`
- `subl` → `subl --wait`

- **Benefit:** You can simply set `editor = "vscode"` in your variables, and this module automatically ensures it runs with the correct flags for interactive shell tasks.

### 2. Dynamic Defaults

Instead of hardcoding specific applications, this module applies the variables passed from `flake.nix` (`term`, `browser`, `editor`) to the system environment.

- **Variables Set:**
- `TERMINAL`: Used by window managers and scripts to launch your preferred terminal.
- `BROWSER`: Used by CLI tools to open links.
- `EDITOR`: Configured dynamically (as described above) for text editing.

### 3. Path Injection

We define `XDG_BIN_HOME` and add it to the system `PATH`.

- **Benefit:** This allows you to place personal scripts or binaries in `~/.local/bin` and run them from anywhere in the terminal, just like standard system commands (`ls`, `cd`, `grep`).

---

## The Code

```nix
{ delib, ... }:
delib.module {
  name = "env";

  nixos.always =
    { myconfig, ... }:
    let
      safeBrowser = myconfig.constants.browser or "firefox";
      safeTerm = myconfig.constants.terminal or "alacritty";
      safeEditor = myconfig.constants.editor or "vscode";

      # Add more if needed
      editorFlags = {
        "code" = "code --wait";
        "vscode" = "code --wait";
        "kate" = "kate --block";
        "gedit" = "gedit --wait";
        "subl" = "subl --wait";
        "nano" = "nano";
        "neovim" = "nvim";
        "nvim" = "nvim";
        "vim" = "vim";
      };

      finalEditor = editorFlags.${safeEditor} or safeEditor;
    in
    {
      environment.localBinInPath = true;

      environment.sessionVariables = {
        BROWSER = safeBrowser;
        TERMINAL = safeTerm;
        EDITOR = finalEditor;
        XDG_BIN_HOME = "$HOME/.local/bin";
      };
    };
}
```

# ~nixOS/nixos/modules/guest.nix

This module implements a fully isolated, ephemeral **Guest Mode**. When enabled (via `guest = true` in `variables.nix`), it creates a specialized user account intended for temporary use by friends or family.

Unlike standard user accounts, the Guest account is designed to be **stateless** and **secure**.

---

## Key Concepts

### 1. Ephemeral Home (`tmpfs`)

The most critical feature of this module is how it handles the guest's home directory.

- **The Mechanism:** Instead of a physical disk partition, `/home/guest` is mounted as a `tmpfs` (RAM disk).
- **The Result:** All files downloaded, cookies saved, or settings changed during the session exist **only in RAM**. As soon as the computer reboots (or the user logs out, effectively), everything is instantly and permanently wiped.

### 2. Forced Desktop Environment (XFCE)

While the main user might use complex environments like Hyprland or KDE, the Guest account is forced to use **XFCE**.

- **Why XFCE?** It is familiar (Windows-like taskbar), lightweight, and stable. It ensures a guest doesn't get confused by tiling window managers.
- **Implementation:** We use `systemd.tmpfiles.rules` to write directly to the `AccountsService` database, forcing the display manager to select `xfce` automatically when the guest logs in.

### 3. Security Hardening

Since a guest is an untrusted user, we apply strict limits:

- **Network Isolation:** If Tailscale (VPN) is active, firewall rules explicitly block the guest from accessing private tailnet IP addresses.
- **Polkit Restrictions:** Custom rules prevent the guest from mounting internal hard drives (protecting your data) or suspending/hibernating the machine.

### 4. User Warning

A custom script (`guest-warning`) runs on login using `zenity`. It displays a bilingual (English/Italian) popup warning the user that "This is a temporary session" and that all files will be deleted upon restart.

---

## The Code

```nix
{ delib
, config
, pkgs
, lib
, ...
}:
delib.module {
  name = "guest";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    let
      guestUid = 2000;

      # 🛡️ THE MONITOR SCRIPT (reboot if on non-XFCE session)
      guestMonitorScript = pkgs.writeShellScriptBin "guest-monitor" ''
        # Safety check: Only run for guest
        if [ "$USER" != "guest" ]; then exit 0; fi

        # 1. CHECK SESSION TYPE
        IS_XFCE=false
        if [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]] || \
           [[ "$DESKTOP_SESSION" == *"xfce"* ]] || \
           [[ "$GDMSESSION" == *"xfce"* ]]; then
           IS_XFCE=true
        fi

        # 2. ACT ACCORDINGLY
        if [ "$IS_XFCE" = true ]; then
           # ✅ WE ARE IN XFCE (ALLOWED)
           sleep 2
           ${pkgs.zenity}/bin/zenity --warning \
             --title="Guest Mode" \
             --text="<span size='large' weight='bold'>⚠️  Guest Session</span>\n\nAll files will be deleted on reboot." \
             --width=400
        else
           # ❌ WE ARE NOT IN XFCE (FORBIDDEN)

           # Show warning in background. User cannot stop what is coming.
           ${pkgs.zenity}/bin/zenity --error \
             --title="Access Denied" \
             --text="<span size='large' weight='bold'>❌ ACCESS DENIED</span>\n\nGuest is restricted to XFCE.\n\n<b>System will reboot in 5 seconds.</b>" \
             --width=400 &

           # Wait 5 seconds
           sleep 5

           # 3. REBOOT THE COMPUTER
           # This is the only way to safely reset the GPU/Drivers from a forbidden Wayland session
           # without causing a black screen hang.
           sudo reboot
        fi
      '';
    in
    {
      users.users.guest = {
        isNormalUser = true;
        description = "Guest Account";
        uid = guestUid;
        group = "guest";
        extraGroups = [
          "networkmanager"
          "audio"
          "video"
        ];
        hashedPassword = "$6$Cqklpmh3CX0Cix4Y$OCx6/ud5bn72K.qQ3aSjlYWX6Yqh9XwrQHSR1GnaPRud6W4KcyU9c3eh6Oqn7bjW3O60oEYti894sqVUE1e1O0";
        createHome = true;
      };

      users.groups.guest.gid = guestUid;

      # 🧹 EPHEMERAL HOME
      fileSystems."/home/guest" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=25%"
          "mode=700"
          "uid=${toString guestUid}"
          "gid=${toString guestUid}"
        ];
      };

      # 🎯 FORCE XFCE PREFERENCE
      systemd.tmpfiles.rules = [
        "d /var/lib/AccountsService/users 0755 root root -"
        "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
        "f /home/.hidden 0644 root root - guest" # Hide the guest folder from file managers if the user is not guest
      ];

      # 🖥️ DESKTOP ENVIRONMENT
      services.xserver.desktopManager.xfce.enable = true;

      # 📦 GUEST PACKAGES
      environment.systemPackages = with pkgs; [
        (firefox.override {
          extraPolicies = {
            DisableFirstRunPage = true;
            DontCheckDefaultBrowser = true;
            DisableTelemetry = true;
          };
        })
        iptables # Firewall management (for the enforcement script)
        file-roller # Archive manager
        zenity # keep for the startup warning
      ];

      environment.xfce.excludePackages = [ pkgs.xfce.parole ];

      environment.etc."xdg/autostart/guest-monitor.desktop".text = ''
        [Desktop Entry]
        Name=Guest Session Monitor
        Exec=${guestMonitorScript}/bin/guest-monitor
        Type=Application
        Terminal=false
      '';

      # 🔓 SUDO RULES FOR REBOOT
      # We allow the guest to run 'reboot' without a password.
      # This is necessary for the enforcement script.
      security.sudo.extraRules = [
        {
          users = [ "guest" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/reboot";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      # 🛡️ FIREWALL
      networking.firewall.extraCommands = lib.mkIf config.services.tailscale.enable ''
        iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -o tailscale0 -j REJECT
        iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -d 100.64.0.0/10 -j REJECT
      '';

      # ⚖️ LIMITS
      systemd.slices."user-${toString guestUid}" = {
        sliceConfig = {
          MemoryMax = "4G";
          CPUWeight = 90;
        };
      };
    };
}
```

---

# ~nixOS/modules/toplevel/mime.nix

This file configures **User-Specific Default Applications** (File Associations). It controls which program launches when you double-click a file or open a link (e.g., ensuring directories open in your chosen File Manager, and URLs open in your chosen Browser).

This is a **Home Manager module** that uses the `xdg.mimeApps` standard. Unlike system-wide defaults, these settings apply only to your user session, allowing different users on the same machine to have different preferences, taken from the host-specific `variables.nix`

---

## Key Concepts

### 1. Dynamic Associations

Instead of hardcoding "firefox" or "dolphin", this module consumes the variables passed from `flake.nix` (`browser`, `editor`, `fileManager`).

- **Benefit:** If you change `editor = "nvim"` to `editor = "code"` in your variables, this file automatically updates all relevant file types (`text/plain`, `application/json`, `text/x-nix`, etc.) to use the new editor without you needing to edit the MIME list manually.

### 2. Desktop File Translation (`mkDesktop`)

Linux applications require exact `.desktop` filenames to register as default handlers (e.g., VS Code is `code.desktop`, not just `code`).

- **The Logic:** We use a helper function `mkDesktop` to translate your simple variable names into the official XDG desktop names:

- `"dolphin"` → `"org.kde.dolphin.desktop"`

- `"vscode"` → `"code.desktop"`

- `"kate"` → `"org.kde.kate.desktop"`

- **Why:** This prevents "Application not found" errors when switching between different tools that have different internal naming conventions.

---

## The Code

```nix
# Set defaults applications. If not enabled the system does not know with what to open file/directories/links and similar
{ delib
, lib
, ...
}:
delib.module {
  name = "mime";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      # If variables are missing, these defaults will be used.
      safeEditor = myconfig.constants.editor or "vscode";
      safeBrowser = myconfig.constants.browser or "firefox";
      safeTerm = myconfig.constants.terminal or "alacritty";
      safeFileManager = myconfig.constants.fileManager or "dolphin";

      termEditors = {
        neovim = {
          bin = "nvim";
          icon = "nvim";
          name = "Neovim (User)";
        };
        nvim = {
          bin = "nvim";
          icon = "nvim";
          name = "Neovim (User)";
        };
        vim = {
          bin = "vim";
          icon = "vim";
          name = "Vim (User)";
        };
        nano = {
          bin = "nano";
          icon = "nano";
          name = "Nano (User)";
        };
        helix = {
          bin = "hx";
          icon = "helix";
          name = "Helix (User)";
        };
      };

      # Check if the chosen editor is a terminal one
      isTermEditor = builtins.hasAttr safeEditor termEditors;
      editorConfig = termEditors.${safeEditor};

      # Resolve browsers that don't follow the "name.desktop" convention
      # Add more as needed
      browserDesktopMap = {
        "vivaldi" = "vivaldi-stable.desktop";
        "brave" = "brave-browser.desktop";
        "chrome" = "google-chrome.desktop";
        "chromium" = "chromium-browser.desktop";
      };

      # EDITOR
      myEditor =
        if isTermEditor then
          "user-${safeEditor}.desktop"
        else if safeEditor == "vscode" || safeEditor == "code" then
          "code.desktop"
        else
          "${safeEditor}.desktop";

      # BROWSER (Uses the map, defaults to name.desktop)
      myBrowser = browserDesktopMap.${safeBrowser} or "${safeBrowser}.desktop";

      # FILE MANAGER
      myFileManager =
        if safeFileManager == "dolphin" then "org.kde.dolphin.desktop" else "${safeFileManager}.desktop";

    in
    {
      # -----------------------------------------------------------------------
      # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
      # -----------------------------------------------------------------------
      xdg.desktopEntries = lib.mkIf isTermEditor {
        "user-${safeEditor}" = {
          name = editorConfig.name;
          genericName = "Text Editor";
          comment = "Edit text files in ${safeTerm}";
          exec = "${safeTerm} -e ${editorConfig.bin} %F";
          icon = editorConfig.icon;
          terminal = false;
          categories = [
            "Utility"
            "TextEditor"
          ];
          mimeType = [
            "text/plain"
            "text/markdown"
            "text/x-nix"
          ];
        };
      };

      # -----------------------------------------------------------------------
      # 📂 MIME ASSOCIATIONS
      # -----------------------------------------------------------------------
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # Directories
          "inode/directory" = myFileManager;

          # Browser
          "text/html" = myBrowser;
          "x-scheme-handler/http" = myBrowser;
          "x-scheme-handler/https" = myBrowser;
          "x-scheme-handler/about" = myBrowser;
          "x-scheme-handler/unknown" = myBrowser;
          "application/pdf" = myBrowser;

          # Editor
          "text/plain" = myEditor;
          "text/markdown" = myEditor;
          "application/x-shellscript" = myEditor;
          "application/json" = myEditor;
          "text/x-nix" = myEditor;

          # Images (defaults to Gwenview)
          "image/jpeg" = "org.kde.gwenview.desktop";
          "image/png" = "org.kde.gwenview.desktop";
          "image/gif" = "org.kde.gwenview.desktop";
          "image/webp" = "org.kde.gwenview.desktop";

        };
      };
    };
}

```

# ~nixOS/modules/toplevel/nix.nix

This file configures the **Nix package manager** itself. It defines how Nix behaves, how it downloads packages, and how it manages disk space.

---

## Key Concepts

### 1. Enabling Flakes

By default, the modern "Flakes" feature (which this entire configuration relies on) is experimental. We explicitly enable `flakes` and the new `nix-command` CLI tool to make the system work.

### 2. Binary Caching (Speed)

Compiling complex software like **Hyprland** from source code can take a long time on every update.

- **Substituters:** We tell Nix to check `hyprland.cachix.org` before trying to build it locally.
- **Trusted Keys:** We cryptographically verify that the binaries coming from that server are legitimate.
- **Result:** Updates take seconds instead of minutes (or hours).

### 3. Automatic Garbage Collection

NixOS keeps every version of your system ever built (boot entries). While useful for rollbacks, this eats up disk space quickly.

- **Policy:** We run the garbage collector **weekly**.
- **Rule:** Any system generation older than **30 days** is deleted. This strikes a balance between having a safety net and keeping the drive clean.

---

## The Code

```nix
{ delib, ... }:
delib.module {
  name = "nix";

  nixos.always = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://hyprland.cachix.org"
        "https://cosmic.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];
    };
    nix.gc.automatic = false;
  };
}

```

# ~nixOS/modules/services/sddm.nix

This file configures **SDDM** (Simple Desktop Display Manager), the graphical login screen that appears when you boot the computer. It handles user authentication and session selection.

---

## Key Concepts

### 1. The "Astronaut" Theme

We use the modern **sddm-astronaut** theme


---

## The Code

```nix
{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "services.sddm";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig
    , ...
    }:
    let
      sddmTheme = pkgs.sddm-astronaut.override {
        embeddedTheme = "hyprland_kath";
        themeConfig = {
          HourFormat = "hh:mm AP";
        };
      };
    in
    {
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];

      services.displayManager.sddm = {
        enable = true;
        wayland.enable = false;
        package = lib.mkForce pkgs.kdePackages.sddm;
        theme = "sddm-astronaut-theme";

        extraPackages = with pkgs; [
          kdePackages.qtsvg # Keep for the theme
          kdePackages.qtmultimedia # Keep for the theme
        ];
      };

      environment.systemPackages = [
        sddmTheme
        pkgs.bibata-cursors
      ];

      services.displayManager.autoLogin = {
        enable = false;
        user = myconfig.constants.user;
      };

      services.getty.autologinUser = null;
    };
}
```

# ~nixOS/modules/toplevel/user.nix

This file defines the **Base Layer** for user configuration. It sets the absolute minimum requirements for a usable user account, regardless of which physical machine the system is running on.

---

## Key Concepts

### 1. The "Safety Net" (Why configure groups twice?)

You might notice that `extraGroups` (permissions) are defined here **and** in the machine-specific `configuration.nix`. This is intentional.

- **Fail-Safe Mechanism:** This file acts as a safety net. If you accidentally delete or break the user configuration in your host file, this module ensures your user **always** has:
- `wheel`: Administrative privileges (`sudo`) to fix the system.
- `networkmanager`: Internet access to download fixes.

**Merging:** Nix automatically combines these groups with the machine-specific ones (like `docker` or `video`) defined in `configuration.nix`.

### 2. Global Shell Enforcement

It set the default shell based on what the user choose as a variable

---

## The Code

```nix
{ delib, pkgs, ... }:
delib.module {
  name = "user";

  nixos.always =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "zsh";

      shellPkg =
        if currentShell == "fish" then
          pkgs.fish
        else if currentShell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      # Bash is enabled by default thus not needed here
      programs.zsh.enable = currentShell == "zsh";
      programs.fish.enable = currentShell == "fish";

      users = {
        defaultUserShell = shellPkg;
        users.${myconfig.constants.user} = {
          isNormalUser = true;
          shell = shellPkg;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
        };
      };
    };
}
```
