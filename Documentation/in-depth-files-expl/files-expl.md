- [~nixOS/flake.nix](#nixosflakenix)
  - [Key Concepts](#key-concepts)
    - [1. The "Two-Pass" Build System](#1-the-two-pass-build-system)
    - [2. Dynamic Variable Merging vs. Module Loading](#2-dynamic-variable-merging-vs-module-loading)
  - [The Code](#the-code)
- [~nixOS/home-manager/home.nix](#nixoshome-managerhomenix)
  - [The Code](#the-code-1)
  - [Key Concepts](#key-concepts-1)
    - [1. User Identity \& State Version](#1-user-identity--state-version)
    - [2. Modular Architecture](#2-modular-architecture)
    - [3. XDG Integration \& KDE Fixes](#3-xdg-integration--kde-fixes)
    - [4. Imperative Actions (Activation Scripts)](#4-imperative-actions-activation-scripts)
  - [The Code](#the-code-2)
- [~nixOS/home-manager/home-packages.nix](#nixoshome-managerhome-packagesnix)
  - [Key Concepts](#key-concepts-2)
    - [1. Dynamic Selection](#1-dynamic-selection)
    - [2. Global vs. Host-Specific](#2-global-vs-host-specific)
    - [3. Critical Dependencies](#3-critical-dependencies)
  - [The Code](#the-code-3)
- [~nixOS/home-manager/modules/gnome/gnome-main.nix](#nixoshome-managermodulesgnomegnome-mainnix)
  - [Key Concepts](#key-concepts-3)
    - [1. Wallpaper Handling (Single Monitor Focus)](#1-wallpaper-handling-single-monitor-focus)
    - [2. Adaptive Theming (Polarity)](#2-adaptive-theming-polarity)
    - [3. Dconf Overrides](#3-dconf-overrides)
  - [The Code](#the-code-4)
- [~nixOS/home-manager/modules/hyprland/hyprland-main.nix](#nixoshome-managermoduleshyprlandhyprland-mainnix)
  - [Key Concepts](#key-concepts-4)
    - [1. Dynamic Monitor Configuration](#1-dynamic-monitor-configuration)
    - [2. Theming Bridge (Catppuccin vs. Stylix)](#2-theming-bridge-catppuccin-vs-stylix)
    - [3. Environment \& Compatibility](#3-environment--compatibility)
    - [4. Smart Rules](#4-smart-rules)
  - [The Code](#the-code-5)
- [~nixOS/home-manager/modules/kde/kde-main.nix](#nixoshome-managermoduleskdekde-mainnix)
  - [Key Concepts](#key-concepts-5)
    - [1. Multi-Monitor Wallpapers](#1-multi-monitor-wallpapers)
    - [2. Dynamic Theme Construction](#2-dynamic-theme-construction)
    - [3. Config Overrides](#3-config-overrides)
  - [The Code](#the-code-6)
- [~nixOS/home-manager/modules/waybar/default.nix](#nixoshome-managermoduleswaybardefaultnix)
  - [Key Concepts](#key-concepts-6)
    - [1. Hybrid Theming (CSS + Nix Variables)](#1-hybrid-theming-css--nix-variables)
    - [2. Host-Specific Customization](#2-host-specific-customization)
    - [3. Dynamic Weather Script](#3-dynamic-weather-script)
  - [The Code](#the-code-7)
- [~nixOS/home-manager/modules/wofi/default.nix](#nixoshome-managermoduleswofidefaultnix)
  - [Key Concepts](#key-concepts-7)
    - [1. Manual Palette Definition](#1-manual-palette-definition)
    - [2. Hybrid Theming Strategy (Semantic Mapping)](#2-hybrid-theming-strategy-semantic-mapping)
    - [3. CSS Injection](#3-css-injection)
  - [The Code](#the-code-8)
- [~nixOS/home-manager/modules/qt.nix](#nixoshome-managermodulesqtnix)
  - [Key Concepts](#key-concepts-8)
    - [1. The "Delicate" Balance (Preventing KDE Crashes)](#1-the-delicate-balance-preventing-kde-crashes)
    - [2. The Engine: Kvantum](#2-the-engine-kvantum)
    - [3. Dynamic Theme Selection](#3-dynamic-theme-selection)
  - [The Code](#the-code-9)
- [~nixOS/home-manager/modules/stylix.nix](#nixoshome-managermodulesstylixnix)
  - [Key Concepts](#key-concepts-9)
    - [1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)](#1-the-traffic-cop-strategy-catppuccin-vs-base16)
    - [2. Preventing Desktop Crashes (The Qt/KDE Conflict)](#2-preventing-desktop-crashes-the-qtkde-conflict)
    - [3. Global Assets](#3-global-assets)
  - [The Code](#the-code-10)
- [~nixOS/home-manager/modules/zsh.nix](#nixoshome-managermoduleszshnix)
  - [Key Concepts](#key-concepts-10)
    - [1. Smart Rebuild Aliases (Impure vs. Pure)](#1-smart-rebuild-aliases-impure-vs-pure)
    - [2. Hybrid Configuration (`.zshrc_custom`)](#2-hybrid-configuration-zshrc_custom)
    - [3. The Startup Sequence](#3-the-startup-sequence)
  - [The Code](#the-code-11)
- [~nixOS/hosts/template-host/configuration.nix](#nixoshoststemplate-hostconfigurationnix)
  - [Key Concepts](#key-concepts-11)
    - [1. Graphical Stability (Preventing Crashes)](#1-graphical-stability-preventing-crashes)
    - [2. Universal Keyboard Layout](#2-universal-keyboard-layout)
    - [3. User \& Host Identity](#3-user--host-identity)
    - [4. Input Method Cleanup (ibus)](#4-input-method-cleanup-ibus)
    - [5. Stop asking for password when screen recording with audio](#5-stop-asking-for-password-when-screen-recording-with-audio)
  - [The Code](#the-code-12)
- [~nixOS/nixos/modules/boot.nix](#nixosnixosmodulesbootnix)
  - [Key Concepts](#key-concepts-12)
    - [1. GRUB vs. systemd-boot](#1-grub-vs-systemd-boot)
    - [2. Dual Boot Support (`os-prober`)](#2-dual-boot-support-os-prober)
    - [3. UEFI Accessibility](#3-uefi-accessibility)
  - [The Code](#the-code-13)
- [~nixOS/nixos/modules/env.nix](#nixosnixosmodulesenvnix)
  - [Key Concepts](#key-concepts-13)
    - [1. Smart Editor Configuration](#1-smart-editor-configuration)
    - [2. Dynamic Defaults](#2-dynamic-defaults)
    - [3. Path Injection](#3-path-injection)
  - [The Code](#the-code-14)
- [~nixOS/nixos/modules/guest.nix](#nixosnixosmodulesguestnix)
  - [Key Concepts](#key-concepts-14)
    - [1. Ephemeral Home (`tmpfs`)](#1-ephemeral-home-tmpfs)
    - [2. Forced Desktop Environment (XFCE)](#2-forced-desktop-environment-xfce)
    - [3. Security Hardening](#3-security-hardening)
    - [4. User Warning](#4-user-warning)
  - [The Code](#the-code-15)
- [🛡️ THE MONITOR SCRIPT](#️-the-monitor-script)
- [~nixOS/nixos/modules/nix.nix](#nixosnixosmodulesnixnix)
  - [Key Concepts](#key-concepts-15)
    - [1. Enabling Flakes](#1-enabling-flakes)
    - [2. Binary Caching (Speed)](#2-binary-caching-speed)
    - [3. Automatic Garbage Collection](#3-automatic-garbage-collection)
  - [The Code](#the-code-16)
- [~nixOS/nixos/modules/sddm.nix](#nixosnixosmodulessddmnix)
  - [Key Concepts](#key-concepts-16)
    - [1. The "Astronaut" Theme](#1-the-astronaut-theme)
    - [2. X11 Backend for Stability](#2-x11-backend-for-stability)
    - [3. UWSM Integration](#3-uwsm-integration)
  - [The Code](#the-code-17)
- [~nixOS/nixos/modules/user.nix](#nixosnixosmodulesusernix)
  - [Key Concepts](#key-concepts-17)
    - [1. The "Safety Net" (Why configure groups twice?)](#1-the-safety-net-why-configure-groups-twice)
    - [2. Global Shell Enforcement](#2-global-shell-enforcement)
  - [The Code](#the-code-18)


# ~nixOS/flake.nix

The `flake.nix` file is the **brain** of the configuration. It is the entry point where Nix starts reading. Its job is not to configure the system (it doesn't set wallpapers or install packages directly), but to **orchestrate** the build process.

It performs three main tasks:

1. **Inputs:** Downloads necessary dependencies (NixOS sources, Home Manager, custom plugins).
2. **Logic:** Defines the blueprint for how to build a "System" (Root) and a "Home" (User).
3. **Outputs:** Loops through the list of hosts and generates the final configuration for each one.

---

## Key Concepts

### 1. The "Two-Pass" Build System

We define two distinct builders functions:

* `makeSystem`: Builds the operating system (`configuration.nix`). It handles bootloaders, drivers, and root-level settings.
* `makeHome`: Builds the user environment (`home.nix`). It handles themes, dotfiles, and user programs.

### 2. Dynamic Variable Merging vs. Module Loading

The build process separates "Data" from "Configuration":

1. **Data Merging (`variables.nix` + `modules.nix`):**
The system loads `variables.nix` and merges it with the optional `modules.nix`. These provide the **inputs** (like "enable hyprland" or "username").
2. **Module Loading (`home.nix`):**
Once the variables are calculated, the system loads the code. It includes the generic `home-manager/home.nix` and, if it exists, adds the specific `hosts/<host>/home.nix` to the load list.

---

## The Code

```nix
{
  description = "My personal nixOS configuration with multi-host support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { nixpkgs
    , nixpkgs-unstable
    , home-manager
    , ...
    }@inputs:
    let

      # Recognize all the hosts intelligently
      hostNames = nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./hosts)
      );

      # 🛠️ SYSTEM BUILDER
      makeSystem =
        hostname:
        let
          # IMPORT VARIABLES FROM FILE
          baseVars = import ./hosts/${hostname}/variables.nix;

          modulesPath = ./hosts/${hostname}/optional/general-hm-modules/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge
          hostVars = baseVars // extraVars // { inherit hostname; };

          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {

          specialArgs = {
            inherit inputs pkgs-unstable;
            # Pass ALL variables from variables.nix to the modules
            vars = hostVars;
          };

          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.nix-sops.nixosModules.sops

            # DE/WM import
            ./nixos/modules/hyprland.nix
            ./nixos/modules/gnome.nix
            ./nixos/modules/kde.nix
            ./nixos/modules/cosmic.nix

            {

              nixpkgs.hostPlatform = hostVars.system;

              nixpkgs.pkgs = import nixpkgs {
                inherit (hostVars) system;
                config.allowUnfree = true;
              };
              time.timeZone = hostVars.timeZone;
            }
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.sharedModules = [
                inputs.catppuccin.homeModules.catppuccin
                inputs.plasma-manager.homeModules.plasma-manager
              ];

              home-manager.extraSpecialArgs = {
                inherit inputs pkgs-unstable hostname;
                vars = hostVars;
              };
              home-manager.users.${hostVars.user} = {
                imports = [
                  ./home-manager/home.nix
                ]

                ++ (
                  if builtins.pathExists ./hosts/${hostname}/optional/general-hm-modules/home.nix then
                    [ ./hosts/${hostname}/optional/general-hm-modules/home.nix ]
                  else
                    [ ]
                )
                ++ (
                  if builtins.pathExists ./hosts/${hostname}/optional/host-hm-modules then
                    [ ./hosts/${hostname}/optional/host-hm-modules ]
                  else
                    [ ]
                );
              };

            }
          ];
        };

      # 🏠 HOME BUILDER
      makeHome =
        hostname:
        let
          # 1. Import Mandatory Variables
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import Optional Modules (nix file) (Safely)
          modulesPath = ./hosts/${hostname}/optional/general-hm-modules/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge them (Extra overrides Base)
          hostVars = baseVars // extraVars // { inherit hostname; };

          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit (hostVars) system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs pkgs-unstable;
            vars = hostVars;
          };

          modules = [
            ./home-manager/home.nix
            inputs.catppuccin.homeModules.catppuccin
            inputs.plasma-manager.homeModules.plasma-manager
          ]
          # 2. Add host-specific host-modules (Home Manager side)
          ++ (nixpkgs.lib.optional (builtins.pathExists ./hosts/${hostname}/optional/host-hm-modules) ./hosts/${hostname}/optional/host-hm-modules)

          # 3. Add host-specific home.nix
          ++ (nixpkgs.lib.optional (builtins.pathExists ./hosts/${hostname}/optional/general-hm-modules/home.nix) ./hosts/${hostname}/optional/general-hm-modules/home.nix);
        };

    in
    {
      # GENERATE CONFIGURATIONS AUTOMATICALLY
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames makeSystem;
      homeConfigurations = nixpkgs.lib.genAttrs hostNames makeHome;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}

```


# ~nixOS/home-manager/home.nix

The `home.nix` file is the **root configuration** for Home Manager. While `configuration.nix` manages the *system* (drivers, bootloader, root users), `home.nix` manages the *user* (dotfiles, themes, user-specific packages).

It serves as the foundation upon which your personal environment is built.


## The Code

```nix
{
  inputs,
  pkgs,
  lib,
  vars,
  ...
}:
{

  # -----------------------------------------------------------------------
  # 🔗 IMPORTS
  # -----------------------------------------------------------------------
  # Pulls in all individual program modules (Hyprland, Zsh, Neovim, etc.)
  imports = [
    ./modules/core.nix
    ./home-packages.nix
  ];

  # -----------------------------------------------------------------------
  # 👤 USER IDENTITY
  # -----------------------------------------------------------------------
  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = vars.homeStateVersion; # Controls backwards compatibility logic
  };

  # -----------------------------------------------------------------------
  # 🏠 HOME MANAGER SELF-MANAGEMENT
  # -----------------------------------------------------------------------
  programs.home-manager.enable = true;

  xdg = {
    enable = true;

    # Ensures mime.nix settings are actually applied
    mimeApps.enable = true;

    # Create default user directories
    # Specific directories can be disabled in the host-specific home.nix file
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Create applications.menu for kde
  # This allow kde applications such as dolphin to pick up the default applications to use for mime types
  xdg.configFile."menus/applications.menu".text = ''
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

  # -----------------------------------------------------------------------
  # 🛠️ ACTIVATION SCRIPTS
  # -----------------------------------------------------------------------
  # DESCRIPTION:
  # Scripts that run during the 'switch' process to perform tasks that
  # declarative Nix cannot do alone (like creating deep subdirectories).
  # -----------------------------------------------------------------------

  home.activation = {

    # ⚠️ Do not add ~/.config/hypr/hyprland.conf otherwise during rebuild the config change and you need to manually reapply home-manager and then logging out/in to see the changes.
    # The file need to be removed manually if needed before rebuilding
    removeExistingConfigs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "/home/${vars.user}/.gtkrc-2.0"
      rm -f "/home/${vars.user}/.config/gtk-3.0/settings.ini"
      rm -f "/home/${vars.user}/.config/gtk-3.0/gtk.css"
      rm -f "/home/${vars.user}/.config/gtk-4.0/settings.ini"
      rm -f "/home/${vars.user}/.config/gtk-4.0/gtk.css"
      rm -f "/home/${vars.user}/.config/dolphinrc"
      rm -f "/home/${vars.user}/.local/share/applications/mimeapps.list"
    '';

    createEssentialDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Screenshots directory (references in other files. Make sure to change accordingly)
      mkdir -p ${vars.screenshots}
    '';
  };
}
```


---

## Key Concepts

### 1. User Identity & State Version

This file establishes who the user is. It receives variables like `user` and `homeStateVersion` from `flake.nix` to dynamically set the username and home directory path (e.g., `/home/krit` vs `/home/template-user`).

### 2. Modular Architecture

Instead of listing every single program here, `home.nix` uses an **imports** list.

* `modules/core.nix`: Use the `core.nix` file to import the specific modules which provide the general experience, such as `lazygit.nix`, `starship.nix` etc.
* `home-packages.nix`: Loads the list of user-installed software. These are software that are available to all hosts.


### 3. XDG Integration & KDE Fixes

This section handles the crucial bridge between your declarative config and how Linux actually finds and launches applications.

* **File Associations (`mimeApps`):**
`xdg.mimeApps.enable = true;` is the switch that activates your `mime.nix` rules. Without this, your preferred default apps (like opening PDFs with Zathura or images with Gwenview) would be ignored.
* **The KDE Launcher & Dolphin Fix (`applications.menu`):**
KDE applications (Dolphin, KRunner) rely on a specific file, `applications.menu`, to build their internal database of installed programs. In pure Window Managers like Hyprland, this file is often missing.
* **The Problem:** If missing, `kbuildsycoca6` (KDE's cache builder) fails. Dolphin won't know that "Gwenview" exists, so it keeps asking you "Which app should I use?" and fails to generate thumbnails.
* **The Fix:** We manually create a standard XDG menu file. This tricks KDE into correctly scanning your system, fixing file associations, thumbnails, and ensuring apps appear correctly in menus.


### 4. Imperative Actions (Activation Scripts)

Nix is declarative (defining *what* should exist), but sometimes we need to perform actions *when* the configuration switches.

* **Cleanup:** We use activation scripts to forcibly remove conflicting config files (like old GTK settings) that might prevent Home Manager from writing new symlinks.
* **Creation:** We ensure essential directories (like `Pictures/screenshots`) exist before applications try to use them.

---

## The Code

```nix
{
  homeStateVersion,
  screenshots,
  user,
  inputs,
  pkgs,
  lib,
  ...
}:
{

  # -----------------------------------------------------------------------
  # 🔌 IMPORTS
  # -----------------------------------------------------------------------
  # Pulls in the modular parts of the configuration.
  imports = [
    # Import the home-manager modules defined in core.nix
    ./modules/core.nix
    
    # The list of software to install for the user
    ./home-packages.nix
  ];

  # -----------------------------------------------------------------------
  # 👤 USER IDENTITY
  # -----------------------------------------------------------------------
  # Create the username and the home directory using the chosen name
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    
    # Controls the state version for Home Manager.
    # This determines which default settings are applied and ensures backward compatibility.
    stateVersion = homeStateVersion; 
  };

  # -----------------------------------------------------------------------
  # ⚙️ HOME MANAGER SELF-MANAGEMENT
  # -----------------------------------------------------------------------
  # Allows Home Manager to manage its own installation and configuration.
  programs.home-manager.enable = true;

  xdg = {
    enable = true;

    # Ensures mime.nix settings are actually applied
    mimeApps.enable = true;

    # Create default user directories
    # Specific directories can be disabled in the host-specific home.nix file
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Create applications.menu for kde
  # This allow kde applications such as dolphin to pick up the default applications to use for mime types
  xdg.configFile."menus/applications.menu".text = ''
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

  # -----------------------------------------------------------------------
  # 🚀 ACTIVATION SCRIPTS
  # -----------------------------------------------------------------------
  # These scripts run every time you rebuild (switch) the home configuration.
  # They handle tasks that pure declarative config cannot do easily.
  home.activation = {
    
    # 1. CLEANUP (Run BEFORE linking new files)
    # Removes conflicting configuration files that might have been created
    # by the OS or desktop environment, allowing Home Manager to overwrite them cleanly.
    # If you find yourself with a clobbered error often that file/directory can be added here
    removeExistingConfigs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "/home/${user}/.gtkrc-2.0"
      rm -f "/home/${user}/.config/gtk-3.0/settings.ini"
      rm -f "/home/${user}/.config/gtk-3.0/gtk.css"
      rm -f "/home/${user}/.config/gtk-4.0/settings.ini"
      rm -f "/home/${user}/.config/gtk-4.0/gtk.css"
      rm -f "/home/${user}/.config/dolphinrc"
    '';

    # 2. SETUP (Run AFTER writing new files)
    # Ensures specific directories exist.
    # The ${screenshots} variable is pulled from variables.nix
    createEssentialDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${screenshots}
    '';
  };
}
```

---

# ~nixOS/home-manager/home-packages.nix

This file defines the **Global Software List** that is installed on *every* machine you own. It combines your personal preferences (defined in variables) with a static list of essential system utilities required for your configuration to function.

---

## Key Concepts

### 1. Dynamic Selection

Instead of hardcoding "firefox" or "neovim", this module intelligently installs the specific applications you selected in `variables.nix` (`term`, `browser`, `fileManager`, `editor`).

* **How it works:** It looks up the package name in the Nixpkgs database.
* **Safety Fallbacks:** If you mistype a name or leave a variable empty, it automatically installs a "safe" default (e.g., `kitty`, `google-chrome`, `dolphin`, `vscode`) so you are never left without a working system.

### 2. Global vs. Host-Specific

* **Edit this file** if you want an application (like `ripgrep` or `htop`) to be available on **all** your computers (desktop, laptop, server).
* **Do NOT edit this file** for machine-specific apps (e.g., install `steam` or `lutris`) if you don't want that package to be installed in all your hosts.
  * The host specific packages should be installed in one of those 2 location inside your specific host folder:
    * `home.nix`: These packages are installed only in the hosts machine but can be configured as a module inside home-manager
    * `local-packages.nix`: These packages are installed only for that host and can not be configured as a home-manager module

### 3. Critical Dependencies

The static list below contains utilities that are **required** for your environment to work correctly (e.g., `ueberzugpp` for file previews, `cliphist` for clipboard history).

* **⚠️ Note:** Do not remove packages from the static list unless you know exactly what you are doing. Each package has an inline comment explaining exactly which feature or script depends on it.

## The Code

```nix
{
  pkgs,
  pkgs-unstable,
  vars,
  ...
}:
let
  # 🔄 TRANSLATION LAYER
  translatedEditor = if vars.editor == "nvim" then "neovim" else vars.editor;

  # 🛡️ SAFE FALLBACKS for browser, fileManager, editor
  # If the user's choice is invalid or missing, these are installed.
  fallbackTerm = pkgs.alacritty;
  fallbackBrowser = pkgs.google-chrome;
  fallbackFileManager = pkgs.kdePackages.dolphin;
  fallbackEditor = pkgs.vscode;

  # 🔍 PACKAGE LOOKUP FUNCTION
  # Tries to find 'pkgs.userInput'. If not found, returns the fallback.
  getPkg =
    name: fallback:
    if builtins.hasAttr name pkgs then
      pkgs.${name}
    else if builtins.hasAttr name pkgs.kdePackages then
      pkgs.kdePackages.${name}
    else
      fallback;

  myTermPkg = getPkg vars.term fallbackTerm;
  myBrowserPkg = getPkg vars.browser fallbackBrowser;
  myFileManagerPkg = getPkg vars.fileManager fallbackFileManager;
  myEditorPkg = getPkg translatedEditor fallbackEditor;
in
{
  home.packages =
    # 1. DYNAMIC INSTALLATION
    # These are installed based on user choices in variables.nix: browser, fileManager, editor
    [
      myTermPkg
      myBrowserPkg
      myFileManagerPkg
      myEditorPkg
    ]

    # 2. STATIC INSTALLATION
    # These are always installed, regardless of user choices
    # Packages in each category are sorted alphabetically
    # ⚠️ All these packages should be kept. The reason is indicated next to each package.
    ++ (with pkgs; [

      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      imv # Image viewer (referenced in window rules)
      mpv # Video player (referenced in window rules)
      pavucontrol # Audio control (Vital for Hyprland and caelestia)

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      cliphist # Wayland clipboard history manager (needed for clipboard management)
      dix # Nix diff viewer between generations
      eza # Modern ls replacement (used by eza.nix module)
      fd # Fast file finder (used in various scripts)
      fzf # Fuzzy finder (used in various scripts)
      git # Version control system (used in various scripts)
      nixfmt-rfc-style # Nix code formatter with RFC style (used in flake.nix)
      starship # Shell prompt (used by starship.nix)
      zoxide # Jump around filesystem (used in various scripts)

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      #

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------
      libnotify # Library for desktop notifications (used by hyprland-notifications)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used in zsh.nix module)
    ])

    # 3. KDE PACKAGES
    ++ (with pkgs.kdePackages; [
      gwenview # Default image viewer as defined in mime.nix
      kio-extras # Extra protocols for KDE file dialogs (needed for dolphin remote access)
      kio-fuse # Mount remote filesystems (via ssh, ftp, etc.) in Dolphin
    ])

    # 4. UNSTABLE PACKAGES
    ++ (with pkgs-unstable; [
      # -----------------------------------------------------------------------
      # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
      # ----------------------------------------------------------------------
    ]);
}
```




# ~nixOS/home-manager/modules/gnome/gnome-main.nix

This file manages the GNOME Desktop Environment settings. Since GNOME stores most of its configuration in a binary database called `dconf`, it is not possible to edit a simple text file like `hyprland.conf`. Instead, Home Manager's `dconf.settings` module is used to inject these settings directly into the database.

---

## Key Concepts

### 1. Wallpaper Handling (Single Monitor Focus)

Unlike Hyprland (which assigns specific wallpapers to specific monitor ports), GNOME handles wallpapers globally.

* **Logic:** We use `builtins.head wallpapers` to grab the **first** wallpaper from your list in `variables.nix`.
* **Fetching:** Nix downloads this image at build time (using `pkgs.fetchurl`) and stores it in the Nix store. We then point GNOME to this immutable path.

### 2. Adaptive Theming (Polarity)

This module respects the `polarity` variable ("dark" or "light") defined in your host configuration.

* It automatically switches the GNOME system interface (`prefer-dark` vs `prefer-light`).
* It selects the appropriate icon theme variant (`Papirus-Dark` vs `Papirus-Light`).

### 3. Dconf Overrides

We use `dconf.settings` to declaratively set preferences that you would normally change in "GNOME Settings" or "GNOME Tweaks".

* **Window Buttons:** We explicitly add Minimize and Maximize buttons, which modern GNOME often hides by default.

---

## The Code

```nix
{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  firstWallpaper = builtins.head vars.wallpapers;
  wallpaperPath = pkgs.fetchurl {
    url = firstWallpaper.wallpaperURL;
    sha256 = firstWallpaper.wallpaperSHA256;
  };

  colorScheme = if vars.polarity == "dark" then "prefer-dark" else "prefer-light";
  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{

  config = lib.mkIf (vars.gnome or false) {
    home.packages =
      (lib.optionals vars.catppuccin [
        (pkgs.catppuccin-gtk.override {
          accents = [ vars.catppuccinAccent ];
          size = "standard";
          tweaks = [
            "rimless"
            "black"
          ];
          variant = vars.catppuccinFlavor;
        })
      ])
      ++ [
        pkgs.papirus-icon-theme
        pkgs.hydrapaper
      ];

    dconf.settings = {

      # --- INTERFACE & THEME ---
      "org/gnome/desktop/interface" = {
        color-scheme = lib.mkForce colorScheme;
        icon-theme = iconThemeName;
      };

      # --- WALLPAPER ---
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
    };
  };
}

```

# ~nixOS/home-manager/modules/hyprland/hyprland-main.nix

This file contains the core configuration for **Hyprland**, a dynamic tiling Wayland compositor. Unlike traditional window managers where you edit a `.conf` file in `~/.config/hypr`, this file generates that configuration dynamically based on your system variables.

It handles window placement, monitors, theming, and startup applications.

---

## Key Concepts

### 1. Dynamic Monitor Configuration

Instead of hardcoding monitor ports (which change between laptops and desktops), this module pulls the `monitors` list from `variables.nix`.

* **Logic:** It iterates through your defined monitors and adds a "fallback" rule (`preferred, auto, 1`) at the end. This ensures that if you plug in a new, undefined monitor, it still works immediately.

### 2. Theming Bridge (Catppuccin vs. Stylix)

This file acts as a bridge between your chosen theme and Hyprland's settings.

* **If Catppuccin is enabled:** It uses the official Catppuccin module variables (`$accent`, `$overlay0`) for borders.
* **If Catppuccin is disabled:** It extracts colors directly from **Stylix** (`config.lib.stylix.colors.base0D`) to match your Base16 theme perfectly.

### 3. Environment & Compatibility

Wayland is newer than X11, so some apps need "convincing" to run correctly. We define a list of **Environment Variables** (`env`) to force apps like VS Code (Electron) and Dolphin (QT) to run in native Wayland mode instead of using the slower XWayland compatibility layer.

### 4. Smart Rules

* **Smart Gaps:** The config includes logic to remove gaps and borders when only one window is on the screen, maximizing screen real estate.
* **Workspace Binding:** It imports `hyprlandWorkspaces` from your host-specific `modules.nix`. This allows the workspaces numbers and binding to be host-specific


---

## The Code

```nix
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.hyprland or false) {
    # ----------------------------------------------------------------------------
    # 🎨 CATPPUCCIN THEME (official module)
    catppuccin.hyprland.enable = vars.catppuccin;
    catppuccin.hyprland.flavor = vars.catppuccinFlavor;
    catppuccin.hyprland.accent = vars.catppuccinAccent;
    # ----------------------------------------------------------------------------

    home.packages = with pkgs; [
      grimblast # Screenshot tool
      hyprpaper # Wallpaper manager
      hyprpicker # Color picker
      brightnessctl # Screen brightness control
      playerctl # Media player control
      showmethekey # Keypress visualizer
      wl-clipboard # Wayland clipboard utilities
      xdg-desktop-portal-hyprland # Required for screen sharing
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      systemd = {
        enable = true;
        variables = [ "--all" ]; # Pass all environment variables to Hyprland systemd service, useful for caelestia-shell
      };

      settings = {

        # -----------------------------------------------------
        # 🌍 Environment Variables
        # -----------------------------------------------------
        # These ensure apps (Electron, QT, etc.) know they are running on Wayland.
        env = [
          # TOOLKIT BACKENDS (Force apps to use Wayland)
          "NIXOS_OZONE_WL,1" # Forces Electron apps (VS Code, Discord, Obsidian) to run natively on Wayland.
          "QT_QPA_PLATFORM,wayland;xcb" # Tells Qt apps: "Try Wayland first. If that fails, use X11 (xcb)".
          "GDK_BACKEND,wayland,x11,*" # Tells GTK apps: "Try Wayland first. If that fails, use X11".
          "SDL_VIDEODRIVER,wayland" # Forces SDL games to run on Wayland (improves performance/scaling).
          "CLUTTER_BACKEND,wayland" # Forces Clutter apps to use Wayland.

          # DESKTOP SESSION IDENTITY
          "XDG_CURRENT_DESKTOP,Hyprland" # Tells portals (screen sharing) that you are using Hyprland.
          "XDG_SESSION_TYPE,wayland" # Generic flag telling the session it is Wayland-based.
          "XDG_SESSION_DESKTOP,Hyprland" # Used by some session managers to identify the desktop.

          # THEMING & AESTHETICS
          "QT_QPA_PLATFORMTHEME,qt5ct" # Tells Qt apps to use the 'qt5ct' or 'qt6ct' tool for styling (fixes ugly Qt apps).

          # SYSTEM PATHS
          "XDG_SCREENSHOTS_DIR,${vars.screenshots}" # Tells tools where to save screenshots by default.

        ];

        # -----------------------------------------------------
        # 🖥️ Monitor Configuration
        # -----------------------------------------------------
        # Syntax: "PORT, RESOLUTION@HERTZ, POSITION, SCALE, TRANSFORM"
        monitor = vars.monitors ++ [
          ",preferred,auto,1" # Fallback in case no monitors are defined in flake.nix
        ];

        # -----------------------------------------------------
        # 🎛️ Main Hyprland apps
        # These are used by other modules using the variable references such as binds.nix
        # -----------------------------------------------------
        "$mainMod" = "SUPER";
        "$term" = vars.term;
        "$fileManager" = "${vars.term} --class yazi -e yazi";
        "$menu" = "wofi";

        # -----------------------------------------------------
        # 🚀 Startup Apps
        # ----------------------------------------------------
        exec-once = [
          "wl-paste --type text --watch cliphist store" # Start clipboard manager for text
          "wl-paste --type image --watch cliphist store" # Start clipboard manager for images
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # Keep for snapper polkit support
          "pkill ibus-daemon" # Kill ibus given by gnome
        ];
        ++ lib.optionals (!(vars.caelestia or false)) [
          "uwsm app -- waybar" # Start waybar onlyt if "caelestia" is disabled in variables.nix
        ];

        # -----------------------------------------------------
        # 🎨 Look & Feel
        # -----------------------------------------------------
        general = {
          gaps_in = 0; # Gaps between windows
          gaps_out = 0; # Gaps between windows and monitor edge
          border_size = 5; # Thickness of window borders

          # 🎨 BORDERS
          # Border colors adapt based on whether catppuccin is enabled
          "col.active_border" =
            if vars.catppuccin then "$accent" else "rgb(${config.lib.stylix.colors.base0D})";

          "col.inactive_border" =
            if vars.catppuccin then "$overlay0" else "rgb(${config.lib.stylix.colors.base03})";

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

        # Layouts are defined in flake.nix and are handled
        # in such a way that they work regardless of desktop environment
        input = {
          kb_layout = vars.keyboardLayout;
          kb_variant = vars.keyboardVariant;
          kb_options = "grp:alt_shift_toggle"; # Alt+Shift to switch layout
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

        windowrulev2 = [
          # --- 1. System & UI Rules ---
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

        ]
        ++ (vars.hyprlandWindowRules or [ ])

        ++ [

          # Prevent apps from auto-maximizing themselves
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          # 1. Force them to FLOAT (detach from tiling grid)
          # 2. Force them to CENTER (relative to the monitor, not the app)
          # 3. Force a fixed SIZE (60% width/height = 20% margin on all sides)
          "float, title:^(Open File|Save As|File Upload|Select a File|Choose wallpaper|Open Folder|Library)(.*)$"
          "center, title:^(Open File|Save As|File Upload|Select a File|Choose wallpaper|Open Folder|Library)(.*)$"
          "size 60% 60%, title:^(Open File|Save As|File Upload|Select a File|Choose wallpaper|Open Folder|Library)(.*)$"

          # Specific fix for XDG Desktop Portal (common Linux file picker)
          "float, class:^(xdg-desktop-portal-gtk)$"
          "center, class:^(xdg-desktop-portal-gtk)$"
          "size 60% 60%, class:^(xdg-desktop-portal-gtk)$"

          # --- 3. original xwayland video bridge rules ---
          "opacity 0.0 override, class:^(xwaylandvideobridge)$"
          "noanim, class:^(xwaylandvideobridge)$"
          "noinitialfocus, class:^(xwaylandvideobridge)$"
          "maxsize 1 1, class:^(xwaylandvideobridge)$"
          "noblur, class:^(xwaylandvideobridge)$"
          "nofocus, class:^(xwaylandvideobridge)$"
        ]
        ++ (vars.hyprlandWindowRules or [ ]);

        workspace = [
          "w[tv1], gapsout:0, gapsin:0" # No gaps if only 1 window is visible
          "f[1], gapsout:0, gapsin:0" # No gaps if window is fullscreen
        ]
        ++ (vars.hyprlandWorkspaces or [ ]);
      };
    };
  };
}
```



# ~nixOS/home-manager/modules/kde/kde-main.nix

This file configures **KDE Plasma 6** using the community-driven `plasma-manager` module. Unlike GNOME (which uses `dconf`), KDE configuration is split across many different text files. `plasma-manager` abstracts this complexity, allowing us to configure the desktop declaratively.

---

## Key Concepts

### 1. Multi-Monitor Wallpapers

KDE Plasma handles wallpapers differently than GNOME. It supports distinct wallpapers for distinct monitors out of the box.

* **Logic:** We pass the **entire list** of wallpapers from `variables.nix`.
* **Behavior:** `plasma-manager` automatically assigns the first wallpaper to the first monitor, the second to the second, and so on.

### 2. Dynamic Theme Construction

KDE themes often require specific naming conventions (e.g., "CatppuccinMochaSky").

* **If Catppuccin is Enabled:** We construct the theme name dynamically by combining the flavor and accent (capitalizing the first letter of each). We also switch the widget style to `kvantum` for better styling support.
* **If Catppuccin is Disabled:** We fall back to the standard "Breeze" themes (Dark or Light) based on the `polarity` variable.

### 3. Config Overrides

We use `overrideConfig = true` to ensure that our declarative settings take precedence over any manual changes made via the GUI. This ensures the system always boots into the correct state, even if settings were messed up previously.

---

## The Code

```nix
{
  pkgs,
  config,
  lib,
  vars,
  ...
}:
let
  # 1. PREPARE WALLPAPERS
  # Converts the list of wallpaper objects into a list of local file paths
  wallpaperFiles = builtins.map (
    wp:
    "${pkgs.fetchurl {
      url = wp.wallpaperURL;
      sha256 = wp.wallpaperSHA256;
    }}"
  ) vars.wallpapers;

  # 2. DETERMINE POLARITY
  # Helper to determine if we are in dark or light mode
  polarity = vars.polarity or "dark";

  # 3. HELPER FUNCTION
  # Capitalizes the first letter of a string (mocha -> Mocha)
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  # 4. CONSTRUCT THEME NAME
  # Builds the exact theme string required by KDE (e.g., "CatppuccinMochaSky")
  theme =
    if vars.catppuccin then
      "Catppuccin${capitalize vars.catppuccinFlavor}${capitalize vars.catppuccinAccent}"
    else if vars.polarity == "dark" then
      "BreezeDark"
    else
      "BreezeLight";

  # 5. LOOK AND FEEL
  lookAndFeel =
    if vars.polarity == "dark" then "org.kde.breezedark.desktop" else "org.kde.breeze.desktop";
  cursorTheme = config.stylix.cursor.name;
in
{

  config = lib.mkIf (vars.kde or false) {

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

      # FORCE SETTINGS
      # Ensures these settings overwrite existing config files on every build
      overrideConfig = lib.mkForce true;

      workspace = {
        clickItemTo = "select"; # Require double-click to open files (Windows-style)

        colorScheme = theme;
        lookAndFeel = lookAndFeel;
        cursor.theme = cursorTheme;

        # Passes the list of wallpapers to Plasma Manager
        # It maps them to monitors sequentially (Monitor 1 -> Wallpaper 1, etc.)
        wallpaper = wallpaperFiles;
      };

      # 6. ADVANCED CONFIG (kdeglobals)
      # Direct edits to the KDE configuration database
      configFile = {
        "kdeglobals"."KDE"."widgetStyle" = if vars.catppuccin then "kvantum" else "Breeze";
        "kdeglobals"."General"."AccentColor" = if vars.catppuccin then "203,166,247" else null; # Manual mauve fallback
      };
    };

    # -----------------------------------------------------------------------
    # 📦 KDE PACKAGES
    # -----------------------------------------------------------------------
    # Apps installed only when KDE is the active desktop
    home.packages = with pkgs.kdePackages; [
      # Theme dependencies
      pkgs.catppuccin-kde
      pkgs.catppuccin-kvantum
    ];

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
    ];
  };
}

```


# ~nixOS/home-manager/modules/waybar/default.nix

This file configures **Waybar**, the status bar used in the Hyprland desktop environment. Unlike standard configurations that use static config files, this module builds the bar dynamically, allowing it to adapt to your theme, location, and host-specific preferences automatically.

---

## Key Concepts

### 1. Hybrid Theming (CSS + Nix Variables) 

Waybar is styled using CSS. To allow switching between themes (like Nord, Dracula, or Catppuccin) without rewriting the CSS file every time, we inject Nix variables directly into the stylesheet.

**Catppuccin Mode:** If Catppuccin is enabled, we rely on the official module for most colors and only define the `@accent` variable based on your selected accent color.


* **Base16 Mode (Fallback):** If Catppuccin is disabled, we manually map generic Base16 hex codes (e.g., `base08`, `base0D`) to readable CSS variable names (e.g., `@red`, `@blue`). This ensures the bar looks correct regardless of which generic theme you choose.



### 2. Host-Specific Customization 

This module consumes the custom variables passed from your host's `modules.nix` file, effectively "personalizing" the bar for the specific machine it is running on.


**`waybarWorkspaceIcons`:** Replaces standard workspace numbers (1, 2, 3) with custom icons (e.g., Terminal, Browser) defined for that specific host.


**`waybarLayoutFlags`:** Replaces the text layout identifier (e.g., "en", "it") with an emoji flag (e.g., "🇺🇸", "🇮🇹").



### 3. Dynamic Weather Script 

Instead of a hardcoded weather widget, we define a `custom/weather` module. It uses the `weather` variable (your city name defined in `variables.nix`) to construct a `curl` command. This fetches live weather data from `wttr.in` and displays the condition icon and temperature.

---

## The Code
This code is my personal one, but it may be change heavily based on your preferences

```nix
{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  cssContent = builtins.readFile ./style.css;

  # Intelligently theme based on whatever catppuccin is enabled or not
  cssVariables =
    if vars.catppuccin then
      ''
        @define-color accent @${vars.catppuccinAccent};
      ''
    else
      ''
        /* 🔴 BASE16 FALLBACK MODE */
        @define-color base   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color text   ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */

        @define-color accent ${config.lib.stylix.colors.withHashtag.base0D}; /* Default Accent */

        /* Map colors used in style.css to Base16 equivalents */
        @define-color red    ${config.lib.stylix.colors.withHashtag.base08};
        @define-color peach  ${config.lib.stylix.colors.withHashtag.base09}; /* Orange */
        @define-color green  ${config.lib.stylix.colors.withHashtag.base0B};
        @define-color teal   ${config.lib.stylix.colors.withHashtag.base0C}; /* Cyan */
        @define-color blue   ${config.lib.stylix.colors.withHashtag.base0D};
        @define-color mauve  ${config.lib.stylix.colors.withHashtag.base0E}; /* Purple */
      '';

in
{
  config = lib.mkIf (vars.hyprland or false) {
    catppuccin.waybar.enable = vars.catppuccin;

    programs.waybar = {
      enable = true;

      # -----------------------------------------------------------------------
      # 🎨 STYLE CONFIGURATION
      # -----------------------------------------------------------------------
      style = lib.mkAfter ''
        ${cssVariables}
        ${cssContent}
      '';

      settings = {
        mainBar = {
          layer = "top"; # "top" layer puts it above normal windows
          position = "top"; # Position on screen (top, bottom, left, right)
          height = 40; # Height in pixels

          # Module Placement
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "hyprland/language"
            "custom/weather"
            "pulseaudio"
            "battery"
            "clock"
            "tray"
          ];

          # -----------------------------------------------------
          # 🗄️ Workspaces Module
          # -----------------------------------------------------
          "hyprland/workspaces" = {
            disable-scroll = true;
            show-special = true; # Show special workspaces (scratchpads)
            special-visible-only = true; # Only show special workspace if it's actually visible
            all-outputs = false; # Only show workspaces that live on the current monitor

            # Format for workspace names and icons
            format = "{name} {icon}";
            format-icons = vars.waybarWorkspaceIcons or { };
          };

          # -----------------------------------------------------
          # ⌨️ Keyboard Layout icons
          # The flag changes based on the current keyboard layout
          # -----------------------------------------------------
          "hyprland/language" = {
            min-length = 5; # prevent layout jumping when flag changes
            tooltip = true; # disable tooltip on hover
          }
          // vars.waybarLayoutFlags or { };

          # -----------------------------------------------------
          # ☁️ Weather
          # -----------------------------------------------------
          "custom/weather" = {
            format = " {} ";
            # Fetches weather for the defined city in flake.nix from wttr.in
            # %c = Condition icon, %t = Temperature
            exec = "curl -s 'wttr.in/${vars.weather}?format=%c%t'";
            interval = 300; # Update every 5 minutes (300 seconds)
            class = "weather";
          };

          # -----------------------------------------------------
          # 🔊 Audio Volume (PulseAudio)
          # -----------------------------------------------------
          "pulseaudio" = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}% "; # Adds Bluetooth icon if connected
            format-muted = "";

            # Icons change based on device type
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
              ]; # Low vol / High vol
            };
            on-click = "pavucontrol"; # Open volume mixer on click
          };

          # -----------------------------------------------------
          # 🔋 Battery Status
          # If no battery is found (eg desktop pc), this module is hidden
          # -----------------------------------------------------
          "battery" = {
            states = {
              warning = 20; # Yellow warning at 20%
              critical = 5; # Red critical at 5%
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%"; # Show plug icon when charging
            format-alt = "{time} {icon}"; # Click to show Time Remaining
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ]; # Icons from empty to full
          };

          # -----------------------------------------------------
          # 🕒 Clock & Calendar
          # -----------------------------------------------------
          "clock" = {
            format = "{:%m/%d/%Y - %I:%M %p}"; # Standard Format: MM/DD/YYYY - HH:MM AM/PM
            format-alt = "{:%A, %B %d at %I:%M %p}"; # Click Format: Full Day Name, Month, Date... When the module is clicked it switches between formats
          };

          # -----------------------------------------------------
          # 📥 System Tray
          # -----------------------------------------------------
          "tray" = {
            icon-size = 20; # Size of tray icons
            spacing = 1; # Space between tray icons
          };
        };
      };
    };
  };
}

```



# ~nixOS/home-manager/modules/wofi/default.nix

This file configures **Wofi**, the application launcher. Wofi uses CSS for styling, which makes it powerful but tricky to theme dynamically with Nix.

To solve this, we implemented a **Manual Palette Injection** system.

---

## Key Concepts

### 1. Manual Palette Definition

Unlike other modules where we might rely on an official Catppuccin plugin, for Wofi we explicitly defined the hex codes for all four Catppuccin flavors (Latte, Frappé, Macchiato, Mocha) directly in this file.

* **Why?** Wofi doesn't support external "theme files" easily. By defining the colors here, we can inject them as CSS variables (`@define-color`) directly into the stylesheet.

### 2. Hybrid Theming Strategy (Semantic Mapping)

The goal is to have **one** `style.css` file that works for *any* theme. We achieve this by mapping specific colors to "Semantic" variable names.

* **If Catppuccin is Enabled:**
1. We look up the user's chosen flavor (e.g., `mocha`) in our manual palette.
2. We define variables like `@mauve`, `@base`, `@text` with the specific hex codes.
3. We map semantic names: `@window_bg` becomes `@base`, `@accent` becomes `@mauve` (or whatever accent you chose).


* **If Catppuccin is Disabled (Base16):**
1. We skip the manual palette entirely.
2. We map the semantic names directly to **Stylix Base16** colors (e.g., `@window_bg` becomes `base00`, `@accent` becomes `base0D`).



### 3. CSS Injection

The final CSS sent to Wofi is a concatenation of:

1. The **Dynamic Variables** block (generated by Nix).
2. The **Static Rules** (read from `style.css`).

This allows the styling rules (padding, border-radius, font-size) to stay in a clean `.css` file while the colors change instantly when you rebuild the system.

---

## The Code

```nix
{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  # 1. Read the CSS file (rules only, no definitions)
  cssContent = builtins.readFile ./style.css;

  # 2. Define the Catppuccin Palettes manually
  palettes = {
    mocha = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
    macchiato = {
      rosewater = "#f4dbd6";
      flamingo = "#f0c6c6";
      pink = "#f5bde6";
      mauve = "#c6a0f6";
      red = "#ed8796";
      maroon = "#ee99a0";
      peach = "#f5a97f";
      yellow = "#eed49f";
      green = "#a6da95";
      teal = "#8bd5ca";
      sky = "#91d7e3";
      sapphire = "#74c7ec";
      blue = "#8aadf4";
      lavender = "#b7bdf8";
      text = "#cad3f5";
      subtext1 = "#b8c0e0";
      subtext0 = "#a5adcb";
      overlay2 = "#939ab7";
      overlay1 = "#8087a2";
      overlay0 = "#6e738d";
      surface2 = "#5b6078";
      surface1 = "#494d64";
      surface0 = "#363a4f";
      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";
    };
    frappe = {
      rosewater = "#f2d5cf";
      flamingo = "#eebebe";
      pink = "#f4b8e4";
      mauve = "#ca9ee6";
      red = "#e78284";
      maroon = "#ea999c";
      peach = "#ef9f76";
      yellow = "#e5c890";
      green = "#a6d189";
      teal = "#81c8be";
      sky = "#99d1db";
      sapphire = "#85c1dc";
      blue = "#8caaee";
      lavender = "#babbf1";
      text = "#c6d0f5";
      subtext1 = "#b5bfe2";
      subtext0 = "#a5adce";
      overlay2 = "#949cbb";
      overlay1 = "#838ba7";
      overlay0 = "#737994";
      surface2 = "#626880";
      surface1 = "#51576d";
      surface0 = "#414559";
      base = "#303446";
      mantle = "#292c3c";
      crust = "#232634";
    };
    latte = {
      rosewater = "#dc8a78";
      flamingo = "#dd7878";
      pink = "#ea76cb";
      mauve = "#8839ef";
      red = "#d20f39";
      maroon = "#e64553";
      peach = "#fe640b";
      yellow = "#df8e1d";
      green = "#40a02b";
      teal = "#179299";
      sky = "#04a5e5";
      sapphire = "#209fb5";
      blue = "#1e66f5";
      lavender = "#7287fd";
      text = "#4c4f69";
      subtext1 = "#5c5f77";
      subtext0 = "#6c6f85";
      overlay2 = "#7c7f93";
      overlay1 = "#8c8fa1";
      overlay0 = "#9ca0b0";
      surface2 = "#acb0be";
      surface1 = "#bcc0cc";
      surface0 = "#ccd0da";
      base = "#eff1f5";
      mantle = "#e6e9ef";
      crust = "#dce0e8";
    };
  };

  # 3. Select the correct palette based on the user's choice
  selectedPalette = palettes.${vars.catppuccinFlavor};

  # 4. Define the CSS Variables Block
  cssVariables =
    if vars.catppuccin then
      ''
        @define-color rosewater ${selectedPalette.rosewater};
        @define-color flamingo ${selectedPalette.flamingo};
        @define-color pink ${selectedPalette.pink};
        @define-color mauve ${selectedPalette.mauve};
        @define-color red ${selectedPalette.red};
        @define-color maroon ${selectedPalette.maroon};
        @define-color peach ${selectedPalette.peach};
        @define-color yellow ${selectedPalette.yellow};
        @define-color green ${selectedPalette.green};
        @define-color teal ${selectedPalette.teal};
        @define-color sky ${selectedPalette.sky};
        @define-color sapphire ${selectedPalette.sapphire};
        @define-color blue ${selectedPalette.blue};
        @define-color lavender ${selectedPalette.lavender};
        @define-color text ${selectedPalette.text};
        @define-color subtext1 ${selectedPalette.subtext1};
        @define-color subtext0 ${selectedPalette.subtext0};
        @define-color overlay2 ${selectedPalette.overlay2};
        @define-color overlay1 ${selectedPalette.overlay1};
        @define-color overlay0 ${selectedPalette.overlay0};
        @define-color surface2 ${selectedPalette.surface2};
        @define-color surface1 ${selectedPalette.surface1};
        @define-color surface0 ${selectedPalette.surface0};
        @define-color base ${selectedPalette.base};
        @define-color mantle ${selectedPalette.mantle};
        @define-color crust ${selectedPalette.crust};

        /* Semantic Mappings */
        @define-color accent      @${vars.catppuccinAccent};
        @define-color window_bg   @base;
        @define-color input_bg    @surface0;
        @define-color selected_bg @surface1;
        @define-color text_color  @text;
      ''
    else
      ''
        /* 🔴 BASE16 FALLBACK MODE */
        /* Map Wofi semantic names to Stylix Base16 colors */
        @define-color window_bg   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color input_bg    ${config.lib.stylix.colors.withHashtag.base01}; /* Lighter Background */
        @define-color selected_bg ${config.lib.stylix.colors.withHashtag.base02}; /* Selection Background */
        @define-color text        ${config.lib.stylix.colors.withHashtag.base05}; 
        @define-color text_color  ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */
        @define-color accent      ${config.lib.stylix.colors.withHashtag.base0D}; /* Blue/Accent */
      '';
in
{

  config = lib.mkIf (vars.hyprland or vars.gnome or vars.kde or vars.cosmic or false) {
    programs.wofi = {
      enable = true;

      settings = {
        show = "drun";
        width = 950;
        height = 500;
        always_parse_args = true;
        show_all = false;
        term = vars.term;
        hide_scroll = true;
        print_command = true;
        insensitive = true;
        prompt = "";
        columns = 2;
        allow_markup = true;
        allow_images = true;
      };

      # Inject variables BEFORE the CSS rules
      style = ''
        ${cssVariables}
        ${cssContent}
      '';
    };
  };
}

```



# ~nixOS/home-manager/modules/qt.nix

This file manages the look and feel of **Qt applications** (like Dolphin, VLC, OBS, KeepassXC). Qt theming on Linux is notoriously difficult because, unlike GTK, it doesn't always respect system settings automatically.

This module acts as a "bridge," ensuring Qt apps look consistent with your chosen theme (Catppuccin or Base16) regardless of the desktop environment you are using.

---

## Key Concepts

### 1. The "Delicate" Balance (Preventing KDE Crashes)

The file contains a warning: `# Do not set QT_QPA_PLATFORMTHEME globally here`. This is the most critical part of this configuration.

* **The Problem:**
* On window managers like **Hyprland**, we **must** set `QT_QPA_PLATFORMTHEME=qt5ct` to tell Qt apps to look for our custom configuration. (We do this in `hyprland-main.nix` ).


* On **KDE Plasma**, the desktop environment *is* Qt. It has its own internal theme manager. If you force `QT_QPA_PLATFORMTHEME=qt5ct` globally in this file, it overrides KDE's internal logic.


* **The Consequence:** If set here, logging into a KDE session would result in a **crash** or a black screen because the desktop itself would try to theme itself using an external tool (`qt5ct`) that isn't running yet.
* **The Solution:** We leave the variable **unset** in this global file. Hyprland sets it for itself, while KDE is left alone to manage itself.

### 2. The Engine: Kvantum

To theme Qt apps, we use **Kvantum**, an SVG-based theme engine.

* **Configuration (`qt5ct`/`qt6ct`):** We use these tools to tell Qt: "Don't use the default style; use Kvantum instead."


**Logic:** We generate the configuration files for `qt5ct` and `qt6ct` declaratively, forcing the `style=kvantum` setting.



### 3. Dynamic Theme Selection

The file dynamically determines which theme Kvantum should load:

**Catppuccin:** It constructs the specific theme name (e.g., `Catppuccin-Mocha-Sky`) using a helper function to match the capitalization required by the folder structure. It then links *only* that specific theme folder from the Nix store to `~/.config/Kvantum`.


**Standard/Stylix:** If Catppuccin is disabled, it falls back to reliable, pre-installed Kvantum themes (`KvGnomeDark` or `KvFlatLight`) based on your host's `polarity` variable.



---

## The Code

```nix
{
  pkgs,
  lib,
  config,
  vars,
  ...
}:

# This file is delicate, if modified without care it can break both Catppuccin and Stylix themes.
let
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  kvantumTheme =
    if vars.catppuccin then
      "Catppuccin-${capitalize vars.catppuccinFlavor}-${capitalize vars.catppuccinAccent}"
    else if vars.polarity == "dark" then
      "KvGnomeDark"
    else
      "KvFlatLight";

  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  config = lib.mkMerge [
    {
      home.sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
        # Do not set QT_QPA_PLATFORMTHEME globally here, otherwise kde plasma crash
      };

      # Install necessary packages for both modes
      home.packages =
        with pkgs;
        [
          libsForQt5.qt5ct
          kdePackages.qt6ct
          libsForQt5.qtstyleplugin-kvantum # Contains the 'kvantummanager' executable
          kdePackages.qtstyleplugin-kvantum
          pkgs.papirus-icon-theme
        ]
        ++ (lib.optionals vars.catppuccin [
          pkgs.catppuccin-kvantum
        ]);
    }

    # --- CONFIG FILES (Apply to BOTH Catppuccin and Stylix modes) ---
    {
      # 1. Kvantum Config (The Theme Engine)
      xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=${kvantumTheme}
      '';

      # 2. QtCT Configs (The Bridge)
      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';

      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';
    }

    # --- CATPPUCCIN SPECIFIC (Only copy theme files if needed) ---
    (lib.mkIf vars.catppuccin {
      xdg.configFile."Kvantum/${kvantumTheme}".source =
        "${pkgs.catppuccin-kvantum}/share/Kvantum/${kvantumTheme}";
    })
  ];
}

```


# ~nixOS/home-manager/modules/stylix.nix

This file configures **Stylix**, the central theming engine for the system. Stylix's job is to take a single "Base16" color scheme (or an image) and automatically inject it into *every* application on your system (Shell, Editor, Browser, Desktop).

However, because we also support the official **Catppuccin** modules, this file acts as a **"Traffic Cop"**. It intelligently decides *who* gets to theme *what*.

---

## Key Concepts

### 1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)

We want the best of both worlds:

* **If Catppuccin is Enabled:** We want the official Catppuccin modules (which are hand-tuned and often look better than generic generated themes) to handle applications like Hyprland, Alacritty, and Bat.
* **If Catppuccin is Disabled:** We want Stylix to automatically generate a theme for *everything* based on the `base16Theme` variable (e.g., Dracula, Gruvbox, Nord).

We achieve this using the `!catppuccin` logic.

* `hyprland.enable = !catppuccin;` → "Only let Stylix theme Hyprland if Catppuccin is false."

### 2. Preventing Desktop Crashes (The Qt/KDE Conflict)

You will notice that **`kde.enable`** and **`qt.enable`** are explicitly set to **`false`**.

* **Misconception:** This does *not* disable Qt support or the KDE desktop.
* **Reality:** This disables **Stylix's attempt to control them**.

**Why is this critical?**
Stylix themes Qt applications by forcing the environment variable `QT_QPA_PLATFORMTHEME` to `qt5ct`.

* **On Hyprland:** This is fine (and necessary).
* **On KDE Plasma:** KDE has its own internal theme engine. If Stylix forces `qt5ct` externally, it conflicts with KDE's internal logic, causing the entire desktop session to **crash** or fail to login.

By setting these to `false`, we tell Stylix: *"Hands off Qt! Let our custom `modules/qt.nix` handle it safely."*

### 3. Global Assets

Regardless of which theme engine we use for apps, Stylix always manages the **universal** assets to ensure consistency:

* **Wallpaper:** Sets the background image.
* **Fonts:** Enforces `JetBrainsMono Nerd Font` everywhere.
* **Cursor:** Enforces the `DMZ-Black` cursor.

---

## The Code

```nix
{
  pkgs,
  lib,
  inputs,
  config,
  vars,
  ...
}:
let
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;
  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = {
    enable = true;
    polarity = vars.polarity; # Sets a global preference for dark mode
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${vars.base16Theme}.yaml";
    image = pkgs.fetchurl {
      url = (builtins.head vars.wallpapers).wallpaperURL;
      sha256 = (builtins.head vars.wallpapers).wallpaperSHA256;
    };

    # -----------------------------------------------------------------------
    # 🎯 TARGETS (Exclusions)
    # -----------------------------------------------------------------------
    # Tells Stylix NOT to automatically skin these programs (except for Firefox).
    targets = {
     # It is possible to enable these, but it require manual theming in the modules/program itself
      neovim.enable = false; # Custom themed via my personal neovim stow config in dotfiles
      wofi.enable = false; # Themed manually via wofi/style.css

      # These should remain disabled because all edge cases are already handled
      waybar.enable = false; # Custom themed via waybar.nix using catppuccin nix https://github.com/catppuccin/nix/blob/95042630028d613080393e0f03c694b77883c7db/modules/home-manager/waybar.nix
      hyprpaper.enable = lib.mkForce false; # Wallpapers are handled manually in flake.nix and are hosts-specific

      # These should absolutely remain disabled because they cause conflicts
      kde.enable = false; # Needed to prevent stylix to override kde settings. Enabling this crash kde plasma session
      qt.enable = false; # Needed to prevent stylix to override qt settings. Enabling this crash kde plasma session

      # These should remain enabled to avoid conflicts with other modules (empty for now)

      # -----------------------------------------------------------------------
      # DE/WM SPECIFIC
      # -----------------------------------------------------------------------
      gnome.enable = vars.gnome;

      # -----------------------------------------------------------------------
      # MULTI EXCLUSIONS DUE TO CAELESTIA/QUICKSHELL
      # -----------------------------------------------------------------------
      gtk.enable = !vars.catppuccin && !vars.cosmic && !vars.caelestia;

      # ---------------------------------------------------------------------------------------
      # 🎨 GLOBAL CATPPUCCIN
      # Intelligently enable/disable stylix based on whether catppuccin is enabled
      # catppuccin = true -> .enable = false
      # catppuccin = false -> .enable = true
      alacritty.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/alacritty.nix
      hyprland.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/main.nix
      hyprlock.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/hyprlock.nix
      swaync.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/swaync/default.nix
      zathura.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/zathura.nix
      bat.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/bat.nix
      lazygit.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/lazygit.nix
      tmux.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/tmux.nix
      starship.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/starship.nix
      cava.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/cava.nix
      kitty.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/kitty.nix
      # ---------------------------------------------------------------------------------------

      # Enable stylix but only for certain elements
      firefox.profileNames = [ vars.user ]; # Applies skin only to the defined profile

      # -----------------------------------------------------------------------
      # Other exclusions
      # This can be enabled but you need to uncomment/remove the module-specific theming file
      # -----------------------------------------------------------------------
      yazi.enable = lib.mkForce false; # Themed manually via yazi-theme.nix
    };

    # -----------------------------------------------------------------------
    # 🖱️ MOUSE CURSOR
    # -----------------------------------------------------------------------
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

    iconTheme = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
  };

  dconf.settings = lib.mkIf vars.catppuccin {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce (if vars.polarity == "dark" then "prefer-dark" else "prefer-light");
    };
  };

  home.sessionVariables = lib.mkIf vars.catppuccin {
    GTK_THEME = "catppuccin-${vars.catppuccinFlavor}-${vars.catppuccinAccent}-standard+rimless,black";

    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
  };

  # 3. Configure GTK Theme &amp; Settings
  gtk = lib.mkIf vars.catppuccin {
    enable = true;

    theme = {
      package = lib.mkForce (
        pkgs.catppuccin-gtk.override {
          accents = [ vars.catppuccinAccent ];
          size = "standard";
          tweaks = [
            "rimless"
            "black"
          ];
          variant = vars.catppuccinFlavor;
        }
      );
      name = lib.mkForce "catppuccin-${vars.catppuccinFlavor}-${vars.catppuccinAccent}-standard+rimless,black";
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = if vars.polarity == "dark" then 1 else 0;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = if vars.polarity == "dark" then 1 else 0;
  };
}
```

# ~nixOS/home-manager/modules/zsh.nix
- Note: `bash.nix` and `fish.nix` do the same thing with slight differences based on the sintax they expect

This file configures **Zsh**, your command-line shell. While Home Manager handles the installation and basic plugins (autosuggestions, syntax highlighting), this module's primary strength lies in its **intelligence**. It adapts its aliases based on the system state and integrates seamlessly with non-Nix dotfiles.

---

## Key Concepts

### 1. Smart Rebuild Aliases (Impure vs. Pure)

The standard `nixos-rebuild` command can be strict. Sometimes you need "impure" builds (e.g., when using files not tracked by Git, like ignored secrets). Instead of remembering complex flags, this module uses the `nixImpure` variable passed from your host config to decide the correct command automatically.

* **If `nixImpure = true`:** The alias `sw` runs `sudo nixos-rebuild switch --flake . --impure`.
* **If `nixImpure = false`:** The alias `sw` runs `nh os switch` (a faster, optimized Nix helper).

**Result:** You just type `sw` on *any* machine, and it does the right thing.

### 2. Hybrid Configuration (`.zshrc_custom`)

Nix is great for system config, but you might have personal shell preferences (aliases, functions, exports) that you want to share with non-Nix machines (like a MacBook or an Ubuntu server).

* **The Logic:** The initialization block looks for a file at `~/.zshrc_custom` and sources it if it exists.
* **The Benefit:** You can manage this file via **GNU Stow** in your personal dotfiles repo. It allows you to keep your generic shell tweaks separate from your OS-specific Nix configuration.

### 3. The Startup Sequence

The `initExtra` block handles the logic that runs every time you open a terminal, ensuring your environment is robust and self-healing:

1. **Hyprland Socket Recovery (The "Dead Session" Fix):** 
* **What it does:** It dynamically searches for the active Hyprland instance signature in `/run/user/...` and exports it.
* **Why it's needed:** This fixes the common "Couldn't connect to socket" error that happens after a reboot or crash, where the shell (or Tmux) tries to talk to an old, dead Hyprland session.


2. **Load Custom Config:** 
* Sources your `stow`-managed `.zshrc_custom` file to load your personal aliases and Git functions.


3. **Tmux Autostart:** 
* Automatically starts a Tmux session, but *only* if you are in a GUI environment (preventing issues in TTYs).


4. **UWSM (Universal Wayland Session Manager):** 
* **Auto-Login:** It detects if you are logging into **TTY1** (the first physical terminal) with no active graphics.
* **Compositor Launch:** If true, it uses `uwsm` to correctly launch your desktop (Hyprland), replacing the need for a bulky display manager like SDDM.


5. **Snapper utilities:** 
* **Create** Allow the user to create a home/root snapshot and lock it if needed
* **Lock/unlock** Allow the user to list and lock/unlock as needed both home-root snapshot
  
6. **Nix prefetch url:**
* **Get the sha256 smartly** It detect if the input is a file or a github repo that need the --unpack flag and give the sha256



---

## The Code
This code is my personal one, but it may be change heavily based on your preferences

```nix
{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

lib.mkIf ((vars.shell or "zsh") == "zsh") {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
    };

    # -----------------------------------------------------------------------
    # ⌨️ SHELL ALIASES (Managed by Nix)
    # -----------------------------------------------------------------------
    shellAliases =
      let
        flakeDir = "~/nixOS";

        isImpure = vars.nixImpure or false;

        switchCmd =
          if isImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

        updateCmd =
          if isImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        updateBoot =
          if isImpure then
            "sudo nixos-rebuild boot --flake . --impure"
          else
            "nh os boot --update ${flakeDir}";
      in
      {
        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        swoff = "cd ${flakeDir} && ${switchCmd} --offline";
        gsw = "cd ${flakeDir} && git add -A && ${switchCmd}";
        gswoff = "cd ${flakeDir} && git add -A && ${switchCmd} --offline";
        upd = "cd ${flakeDir} && ${updateCmd}";

        # Manual are kept for reference, but use the above aliases instead
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # System maintenance
        dedup = "nix store optimise";
        cleanup = "nh clean all";
        gc = "nix-collect-garbage -d";

        # Home-Manager related (). Currently disabled because "sw" handle also home manager. Kept for reference
        # hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#${vars.hostname}"; # Rebuild home-manager config

        # Pkgs editing
        pkgs-home = "$EDITOR ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${vars.hostname}/optional/host-packages/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch
        cdnix = "cd ${flakeDir}";

        # Snapshots
        snap-list-home = "snapper -c home list"; # List home snapshots
        snap-list-root = "sudo snapper -c root list"; # List root snapshots

        # Utilities
        se = "sudoedit";
        fzf-prev = "fzf --preview=\"cat {}\"";
        fzf-editor = "${vars.editor} \$(fzf -m --preview='cat {}')";

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir} && sops common/${vars.user}-common-secrets-sops.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${vars.hostname}/optional/host-sops-nix/${vars.hostname}-secrets-sops"; # Edit host-specific sops secrets file

        # Various
        reb-uefi = "systemctl reboot --firmware-setup"; # Reboot into UEFI firmware settings
        updboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    # -----------------------------------------------------
    # ⚙️ SHELL INITIALIZATION
    # -----------------------------------------------------
    initExtra = ''
        # 1. FIX HYPRLAND SOCKET (Dynamic Update)
        if [ -d "/run/user/$(id -u)/hypr" ];
        then
          # Search for the actual socket file (Removed 'local' to fix error)
          socket_file=$(find /run/user/$(id -u)/hypr/ -name ".socket.sock" -print -quit)
          if [ -n "$socket_file" ];
          then
            export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname "$socket_file"))
          fi
        fi

        # 2. LOAD USER CONFIG
        if [ -f "$HOME/.zshrc_custom" ]; then
          source "$HOME/.zshrc_custom"
        fi

        # 3. TMUX AUTOSTART (Only in GUI)
        # Ensure we are in a GUI before starting tmux automatically
        if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
          tmux new-session -A -s main
        fi

        # 4. UWSM STARTUP (Universal & Safe)
        # Guard: Only run if on physical TTY1 AND no graphical session is active.
        if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
            
            # Check if uwsm is installed and ready (Safe for KDE/GNOME-only builds)
            if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                exec systemd-cat -t uwsm_start uwsm start default
            fi
        fi

        # -----------------------------------------------------
        # 5A SNAPSHOT LOCK & UNLOCK
        # -----------------------------------------------------
        # LOCK (Protect from auto-deletion)
        snap-lock() {
          echo "Which config? (1=home, 2=root)"
          read "k?Selection: "
          if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
          
          echo "Listing snapshots for $CFG..."
          sudo snapper -c "$CFG" list
          
          echo ""
          read "ID?Enter Snapshot ID to LOCK: "
          
          if [[ -n "$ID" ]]; then
             sudo snapper -c "$CFG" modify -c "" "$ID"
             echo "✅ Snapshot #$ID in '$CFG' is now LOCKED (won't be deleted)."
          fi
        }

        # UNLOCK (Allow auto-deletion)
        snap-unlock() {
          echo "Which config? (1=home, 2=root)"
          read "k?Selection: "
          if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
          
          echo "Listing snapshots for $CFG..."
          sudo snapper -c "$CFG" list
          
          echo ""
          read "ID?Enter Snapshot ID to UNLOCK: "
          
          if [[ -n "$ID" ]]; then
             sudo snapper -c "$CFG" modify -c "timeline" "$ID"
             echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED (timeline cleanup enabled)."
          fi
        }


      # -----------------------------------------------------------------------
      # 5B SNAPPER CREATE INTERACTIVE FUNCTION
      # -----------------------------------------------------------------------
      function _snap_create() {
        local config_name=$1
        
        echo -n "📝 Enter snapshot description: "
        read description
        
        if [ -z "$description" ]; then
          echo "❌ Description cannot be empty."
          return 1
        fi

        echo -n "🔒 Lock this snapshot (keep forever)? [y/N]: "
        read lock_ans

        local cleanup_flag="-c timeline"
        local lock_status="UNLOCKED (will auto-delete)"

        if [[ "$lock_ans" =~ ^[Yy]$ ]]; then
          cleanup_flag=""
          lock_status="LOCKED (safe forever)"
        fi

        echo "🚀 Creating $lock_status snapshot for '$config_name'..."
        sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
      }

      alias snap-create-home="_snap_create home"
      alias snap-create-root="_snap_create root"

      # -----------------------------------------------------
      # 6 📦 SMART NIX PREFETCH (npu)
      # -----------------------------------------------------
      npu() {
        local url
        if [ -z "$1" ]; then
          read "url?Enter URL: "
        else
          url="$1"
        fi

        # Detect if the URL is a GitHub/GitLab repository archive
        if [[ "$url" == *"github.com"* ]] || [[ "$url" == *"gitlab.com"* ]]; then
          echo "📦 Git repository detected. Using --unpack for Nix compatibility..."
          nix-prefetch-url --unpack "$url"
        else
          echo "📄 Direct file detected. Fetching normally..."
          nix-prefetch-url "$url"
        fi
      }
    '';
  };
}
```

# ~nixOS/hosts/template-host/configuration.nix

This file is the **machine-specific** entry point for NixOS. While `flake.nix` orchestrates the build, this file defines the physical reality of the specific computer (its hardware, hostname, and core system packages).
- This is the file that provide the simplest working environment. Other hosts can have a different one

---

## Key Concepts

### 1. Graphical Stability (Preventing Crashes)

It nstall essential terminals graphics libraries (`qtwayland`) at the **system level** rather than inside the optional Desktop Environment modules.

* **The Problem:** If you were to install these libraries only inside the `kde.nix` module, and then decided to disable KDE (to use only Hyprland, for example), your terminals or Qt applications might crash because they would lose the necessary display backend tools.
* **The Solution:** By defining them here, we ensure that graphical applications always have the right tools to be displayed, regardless of which Desktop Environment is enabled or disabled.

### 2. Universal Keyboard Layout

Instead of configuring the keyboard in three different places (X11, Wayland, Console), we set it once here using the `keyboardLayout` variable. The `console.useXkbConfig = true` line forces the text-only TTY to inherit the layout defined for the graphical server, ensuring consistency everywhere.

### 3. User & Host Identity

This file consumes the variables passed from `flake.nix` (like `user`, `hostname`, `stateVersion`) to dynamically configure the user account and network identity without hardcoding values.


### 4. Input Method Cleanup (ibus)

We explicitly disable the `ibus` input method system and force-clear related environment variables at the end of the configuration.

* **The Problem:** The `ibus` daemon (used for typing complex characters in languages like Japanese or Chinese) often runs by default and "hijacks" keyboard input. In tiling window managers (like Hyprland) or games, this frequently causes "dead keys" (keys that don't register immediately) or interferes with custom keybindings.
* **The Solution:** By using `lib.mkForce null` on the input method and clearing `GTK_IM_MODULE`/`QT_IM_MODULE`, we ensure that the keyboard sends raw, direct input to your applications without any software layer interfering.


### 5. Stop asking for password when screen recording with audio

It uses `gpu-screen-recorder` and allow members of the group `wheel` to run audio recording commands as root


---

## The Code

```nix
{
  config,
  pkgs,
  lib,
  user,
  stateVersion,
  hostname,
  keyboardLayout,
  keyboardVariant,
  ...
}:
let
  # Determine which shell package to use based on the variable
  shellPkg =
    if vars.shell == "fish" then
      pkgs.fish
    else if vars.shell == "zsh" then
      pkgs.zsh
    else
      pkgs.bashInteractive;
in
{
  # home.nix and host-modules are imported from flake.nix
  imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./optional/host-packages/default.nix

    # Core imports
    ../../nixos/modules/core.nix
  ];

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🔐 SOPS CONFIGURATION
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*
    sops.defaultSopsFile = ./optional/host-sops-nix/<hostname>-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  */

  hardware.graphics.enable = true; # Keep enabled to avoid terminal crash when disabling certain de

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Primary monospace font; includes icons for coding and terminal use
    nerd-fonts.symbols-only # Icon fallback; ensures symbols render even when the main font lacks them
    noto-fonts # Base text coverage; Google's "No Tofu" standard to fix square boxes globally
    dejavu_fonts # Core Linux fallback; high compatibility for standard text in older apps
    noto-fonts-lgc-plus # Extended European support; covers complex Latin, Greek, and Cyrillic variants
    noto-fonts-color-emoji # Emoji support; ensures emojis appear in color rather than monochrome outlines
    noto-fonts-cjk-sans # Asian language support; mandatory for Chinese, Japanese, and Korean characters
    texlivePackages.hebrew-fonts # Hebrew support; specialized font for correct Hebrew script rendering
    font-awesome # System icons; standard dependency for Waybar and desktop interface elements
    powerline-fonts # Shell prompt glyphs; prevents broken triangles/shapes in Zsh/Bash prompts
  ];

  fonts.fontconfig.enable = true;

  environment.systemPackages = with pkgs; [
    foot # Tiny, zero-config terminal; critical rescue tool if your main terminal config breaks
    iptables # Core firewall utility; base dependency for network security and containers
    glib # Low-level system library; almost all software crashes without this base layer
    gpu-screen-recorder # Used for caelestia and included here to ensure proper permissions
    # Global theme settings; prevents GTK apps from looking broken or crashing
    gsettings-desktop-schemas
    gtk3 # Standard GUI toolkit; essential for drawing basic application windows
    libsForQt5.qt5.qtwayland # Qt5 Wayland bridge; mandatory for older Qt apps to display correctly
    kdePackages.qtwayland # Qt6 Wayland bridge; mandatory for modern Qt apps to display correctly
    powerline-symbols # Terminal font glyphs; prevents "box" errors in shell prompts
    polkit_gnome # Authentication agent; required for GUI apps (like Btrfs Assistant) to ask for passwords
    sops # Secret management tool; decrypts sensitive data stored in Git repositories
    shellPkg # The selected shell package (bash, zsh, or fish)
  ];

  programs.dconf.enable = true;

  programs.zsh.enable = true;

  security.wrappers.gpu-screen-recorder = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
  };

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY
  # ---------------------------------------------------------
  # Dynamically sets the hostname passed from flake.nix
  networking.hostName = hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # -----------------------------------------------------
  # ⚡ Systemd Shutdown Tweak
  # -----------------------------------------------------
  # This reduces the wait time for stuck services from 90s to 10s.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };

  # ---------------------------------------------------------
  # ⌨️ KEYBOARD LAYOUT (Global Logic)
  # ---------------------------------------------------------
  # Applies the layout defined in flake.nix to X11, Wayland, and Console.
  # This ensures that all the desktop environments and TTYs use the same layout.
  services.xserver.xkb = {
    layout = keyboardLayout;
    variant = keyboardVariant;
  };

  # Forces the text console (TTY) to look at the Xserver settings above.
  console.useXkbConfig = true;

  # ---------------------------------------------------------
  # 🛡️ SECURITY & REALTIME AUDIO
  # ---------------------------------------------------------
  security.rtkit.enable = true;

  # Allow members of "wheel" to:
  # 1. Get realtime audio priority (fixes audio recording prompt)
  # 2. Run commands as root via pkexec (fixes gpu-screen-recorder prompt)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        // Auto-approve realtime audio requests
        if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
            action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
          return polkit.Result.YES;
        }
        
        // Auto-approve gpu-screen-recorder running as root
        // (Caelestia uses pkexec to launch it)
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") && 
            action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  # Defines the user dynamically based on flake.nix input
  users.users.${user} = {
    isNormalUser = true;
    description = "Primary user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      #"docker"
      #"podman"
      "video"
      "audio"
    ];
    shell = pkgs.zsh; # Ensure zsh is installed in system packages
  };

  # This is needed if you want to use docker and be part of the docker/podman group

  # Required for rootless Podman/Distrobox
  /*
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];

    virtualisation.docker.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = false; # Allows Podman to answer to 'docker' commands (false as it clash with docker)
    };
  */

  # ---------------------------------------------------------
  # 🗑️ AUTO TRASH CLEANUP
  # ---------------------------------------------------------
  # Trash cleanup service that deletes files older than 30 days

  /*
    systemd.services.cleanup_trash = {
      description = "Clean up trash older than 30 days";
      serviceConfig = {
        Type = "oneshot";
        User = vars.user;
        Environment = "HOME=/home/${vars.user}";
        ExecStart = "${pkgs.autotrash}/bin/autotrash -d 30";
      };
    };
  */

  # Nix Settings (Flakes & Garbage Collection)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Defines the state version dynamically based on flake.nix input
  system.stateVersion = stateVersion;

  i18n.inputMethod.enabled = lib.mkForce null;
  environment.variables.GTK_IM_MODULE = lib.mkForce "";
  environment.variables.QT_IM_MODULE = lib.mkForce "";
  environment.variables.XMODIFIERS = lib.mkForce "";
}
```

# ~nixOS/nixos/modules/boot.nix

This file handles the **Bootloader configuration**. It determines what you see when you first turn on your computer and how the operating system loads.

While NixOS defaults to `systemd-boot` for modern UEFI systems, this module explicitly switches to **GRUB**.

---

## Key Concepts

### 1. GRUB vs. systemd-boot

By default, NixOS uses `systemd-boot` because it is simple and fast. However, we force it off (`lib.mkForce false`) and enable **GRUB** instead.

* **Why?** GRUB is generally better at detecting other operating systems (Dual Booting) and offers more customization options for themes and visual styles.

### 2. Dual Boot Support (`os-prober`)

We enable `useOSProber = true`. This tells GRUB to scan your hard drives for other operating systems (like Windows or another Linux distro) and automatically add them to the boot menu. This is essential for dual-boot setups.

### 3. UEFI Accessibility

We add a custom menu entry called **"UEFI Firmware Settings"**.

* **The Benefit:** This allows you to reboot directly into your BIOS/UEFI settings from the boot menu, without needing to spam a certain key on the keyboard.

---

## The Code

```nix
{ pkgs, lib, ... }:
{
  boot.loader = {
    # ⏳ TIMEOUT
    # Gives you 30 seconds to choose an OS before booting the first one in the list
    timeout = 30;

    # 🔧 EFI SETTINGS
    # Allows NixOS to modify EFI variables (needed to register the bootloader)
    efi.canTouchEfiVariables = true;

    # 🚫 DISABLE SYSTEMD-BOOT
    # We force this off to prevent conflicts with GRUB
    systemd-boot.enable = lib.mkForce false;

    # grub 🐌 ENABLE GRUB
    grub = {
      enable = lib.mkForce true;
      
      # 'nodev' is the standard value for UEFI systems 
      # (GRUB doesn't install to the MBR of a specific device like /dev/sda)
      device = "nodev";
      
      efiSupport = true;
      
      # 🕵️ DUAL BOOT
      # Scans for Windows/other Linux installs
      useOSProber = true;

      
      # Ensures the boot entry is named cleanly in your BIOS
      extraGrubInstallArgs = [ "--bootloader-id=nixos" ];

      # 🛠️ EXTRA MENU ENTRIES
      # Adds a button to reboot into BIOS
      extraEntries = ''
        menuentry "UEFI Firmware Settings" {
          fwsetup
        }
      '';
    };
  };
}
```

---

# ~nixOS/nixos/modules/env.nix

This file defines global **Environment Variables** that are available to all users and processes on the system. It ensures that your preferred tools (like your terminal, browser, and editor) are recognized as defaults by the operating system and other applications.

---

## Key Concepts

### 1. Smart Editor Configuration

Setting the `EDITOR` variable isn't always straightforward. Some GUI editors (like VS Code or Kate) return control to the terminal immediately, which breaks tools like `git commit` that need to wait for you to save and close the file.

* **The Solution:** We use a **Translation Layer** (`editorFlags`) that automatically appends the necessary flags to your chosen editor:
* `vscode` → `code --wait`
* `kate` → `kate --block`
* `subl` → `subl --wait`


* **Benefit:** You can simply set `editor = "vscode"` in your variables, and this module automatically ensures it runs with the correct flags for interactive shell tasks.

### 2. Dynamic Defaults

Instead of hardcoding specific applications, this module applies the variables passed from `flake.nix` (`term`, `browser`, `editor`) to the system environment.

* **Variables Set:**
* `TERMINAL`: Used by window managers and scripts to launch your preferred terminal.
* `BROWSER`: Used by CLI tools to open links.
* `EDITOR`: Configured dynamically (as described above) for text editing.



### 3. Path Injection

We define `XDG_BIN_HOME` and add it to the system `PATH`.

* **Benefit:** This allows you to place personal scripts or binaries in `~/.local/bin` and run them from anywhere in the terminal, just like standard system commands (`ls`, `cd`, `grep`).

---

## The Code

```nix
{
  vars,
  ...
}:

let
  # Translation layer for editor commands with necessary flags
  # It may be necessary to add more editors and their flags here
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

  # Select the correct command, or default to the name itself if unknown
  finalEditor = editorFlags.${vars.editor} or vars.editor;
in
{

  environment.localBinInPath = true;

  environment.sessionVariables = {
    BROWSER = vars.browser;

    TERMINAL = vars.term;

    EDITOR = finalEditor;

    XDG_BIN_HOME = "$HOME/.local/bin";
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

* **The Mechanism:** Instead of a physical disk partition, `/home/guest` is mounted as a `tmpfs` (RAM disk).
* **The Result:** All files downloaded, cookies saved, or settings changed during the session exist **only in RAM**. As soon as the computer reboots (or the user logs out, effectively), everything is instantly and permanently wiped.

### 2. Forced Desktop Environment (XFCE)

While the main user might use complex environments like Hyprland or KDE, the Guest account is forced to use **XFCE**.

* **Why XFCE?** It is familiar (Windows-like taskbar), lightweight, and stable. It ensures a guest doesn't get confused by tiling window managers.
* **Implementation:** We use `systemd.tmpfiles.rules` to write directly to the `AccountsService` database, forcing the display manager to select `xfce` automatically when the guest logs in.

### 3. Security Hardening

Since a guest is an untrusted user, we apply strict limits:

* **Network Isolation:** If Tailscale (VPN) is active, firewall rules explicitly block the guest from accessing private tailnet IP addresses.
* **Polkit Restrictions:** Custom rules prevent the guest from mounting internal hard drives (protecting your data) or suspending/hibernating the machine.

### 4. User Warning

A custom script (`guest-warning`) runs on login using `zenity`. It displays a bilingual (English/Italian) popup warning the user that "This is a temporary session" and that all files will be deleted upon restart.

---

## The Code

{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

let
  guestUid = 2000;

  # 🛡️ THE MONITOR SCRIPT
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
  config = lib.mkIf (vars.guest or false) {

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
    ];

    # 🖥️ DESKTOP ENVIRONMENT
    services.xserver.desktopManager.xfce.enable = true;

    # 📦 GUEST PACKAGES
    environment.systemPackages = with pkgs; [
      (google-chrome.override { commandLineArgs = "--no-first-run --no-default-browser-check"; })
      file-roller # Archive manager
      zenity # keep for the startup warning
    ];

    environment.xfce.excludePackages = [
      pkgs.xfce.parole
    ];

    # ⚠️ UNIVERSAL AUTOSTART MONITOR
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

# ~nixOS/home-manager/modules/mime.nix

This file configures **User-Specific Default Applications** (File Associations). It controls which program launches when you double-click a file or open a link (e.g., ensuring directories open in your chosen File Manager, and URLs open in your chosen Browser).

This is a **Home Manager module** that uses the `xdg.mimeApps` standard. Unlike system-wide defaults, these settings apply only to your user session, allowing different users on the same machine to have different preferences, taken from the host-specific `variables.nix`

---

## Key Concepts

### 1. Dynamic Associations

Instead of hardcoding "firefox" or "dolphin", this module consumes the variables passed from `flake.nix` (`browser`, `editor`, `fileManager`).

* **Benefit:** If you change `editor = "nvim"` to `editor = "code"` in your variables, this file automatically updates all relevant file types (`text/plain`, `application/json`, `text/x-nix`, etc.) to use the new editor without you needing to edit the MIME list manually.

### 2. Desktop File Translation (`mkDesktop`)

Linux applications require exact `.desktop` filenames to register as default handlers (e.g., VS Code is `code.desktop`, not just `code`).

* 
**The Logic:** We use a helper function `mkDesktop`  to translate your simple variable names into the official XDG desktop names:


* 
`"dolphin"` → `"org.kde.dolphin.desktop"` 


* 
`"vscode"` → `"code.desktop"` 


* 
`"kate"` → `"org.kde.kate.desktop"` 




* **Why:** This prevents "Application not found" errors when switching between different tools that have different internal naming conventions.

---

## The Code
```nix
{
  pkgs,
  vars,
  lib,
  ...
}:
let
  # -----------------------------------------------------------------------
  # 1. HELPER: Terminal Editor Logic
  # -----------------------------------------------------------------------
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
  isTermEditor = builtins.hasAttr vars.editor termEditors;
  editorConfig = termEditors.${vars.editor};

  # -----------------------------------------------------------------------
  # 2. LOGIC: Determine the .desktop file name
  # -----------------------------------------------------------------------
  myEditor =
    if isTermEditor then
      # If it's a terminal editor, use our custom generated file
      "user-${vars.editor}.desktop"
    else
    # If it's a GUI editor (VSCode), use the standard system file
    if vars.editor == "vscode" || vars.editor == "code" then
      "code.desktop"
    else
      "${vars.editor}.desktop";

  myBrowser = "${vars.browser}.desktop";
  myFileManager =
    if vars.fileManager == "dolphin" then "org.kde.dolphin.desktop" else "${vars.fileManager}.desktop";

in
{
  # -----------------------------------------------------------------------
  # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
  # -----------------------------------------------------------------------
  # This creates a file like: ~/.local/share/applications/user-neovim.desktop
  xdg.desktopEntries = lib.mkIf isTermEditor {
    "user-${vars.editor}" = {
      name = editorConfig.name;
      genericName = "Text Editor";
      comment = "Edit text files in ${vars.term}";
      exec = "${vars.term} -e ${editorConfig.bin} %F";
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
      "inode/directory" = myFileManager;

      "text/html" = myBrowser;
      "x-scheme-handler/http" = myBrowser;
      "x-scheme-handler/https" = myBrowser;
      "x-scheme-handler/about" = myBrowser;
      "x-scheme-handler/unknown" = myBrowser;

      # Force these types to use our calculated 'myEditor'
      "text/plain" = myEditor;
      "text/markdown" = myEditor;
      "application/x-shellscript" = myEditor;
      "application/json" = myEditor;
      "text/x-nix" = myEditor;

      # Images
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/png" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";

      # PDFs
      "application/pdf" = myBrowser;
    };
  };
}
```

# ~nixOS/nixos/modules/nix.nix

This file configures the **Nix package manager** itself. It defines how Nix behaves, how it downloads packages, and how it manages disk space.

---

## Key Concepts

### 1. Enabling Flakes

By default, the modern "Flakes" feature (which this entire configuration relies on) is experimental. We explicitly enable `flakes` and the new `nix-command` CLI tool to make the system work.

### 2. Binary Caching (Speed)

Compiling complex software like **Hyprland** from source code can take a long time on every update.

* **Substituters:** We tell Nix to check `hyprland.cachix.org` before trying to build it locally.
* **Trusted Keys:** We cryptographically verify that the binaries coming from that server are legitimate.
* **Result:** Updates take seconds instead of minutes (or hours).

### 3. Automatic Garbage Collection

NixOS keeps every version of your system ever built (boot entries). While useful for rollbacks, this eats up disk space quickly.

* **Policy:** We run the garbage collector **weekly**.
* **Rule:** Any system generation older than **30 days** is deleted. This strikes a balance between having a safety net and keeping the drive clean.

---

## The Code

```nix
{
  # -----------------------------------------------------------------------
  # ⚙️ NIX PACKAGE MANAGER SETTINGS
  # -----------------------------------------------------------------------

  nix.settings = {
    # 🔓 ENABLE FLAKES
    # Necessary for this configuration structure to work.
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Deduplicate exact files in the Nix store to save space
    auto-optimise-store = true;

    # 🚀 BINARY CACHES
    # Tells Nix to download pre-built binaries for Hyprland instead of 
    # compiling them from source (which takes forever).
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # 🧹 GARBAGE COLLECTION
  # Automatically cleans up old system generations to save disk space.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
```

# ~nixOS/nixos/modules/sddm.nix

This file configures **SDDM** (Simple Desktop Display Manager), the graphical login screen that appears when you boot the computer. It handles user authentication and session selection.

---

## Key Concepts

### 1. The "Astronaut" Theme

We use the modern **sddm-astronaut** theme (specifically the `jake_the_dog` variant).

**Dependencies:** To ensure the theme renders correctly (with animations and icons), we explicitly inject Qt libraries like `qtsvg`, `qtmultimedia`, and `qtvirtualkeyboard` into SDDM's environment.



### 2. X11 Backend for Stability

Even though we might be logging into a Wayland session (like Hyprland), the login screen itself is configured to run on **X11** (`wayland.enable = false`).

* **Why?** SDDM's Wayland mode can sometimes be buggy or fail to load themes correctly. Running the login screen on X11 is a "set it and forget it" stability measure that doesn't affect the performance of your actual desktop session.



### 3. UWSM Integration

If **Hyprland** is enabled, we set the default session to **`hyprland-uwsm`**.

* **Significance:** This tells SDDM to launch Hyprland using the **Universal Wayland Session Manager** (UWSM) rather than the raw binary. This ensures that systemd services, environment variables, and cleanup processes are handled correctly during login and logout.

---

## The Code

```nix
{ pkgs
, lib
, vars
, ...
}:
let
  # Reference for themes:
  # Files: https://github.com/Keyitdev/sddm-astronaut-theme/tree/master/themes
  sddmTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath"; # do not include ".conf" at the end
    themeConfig = {
      # Clock format. The default is 24/h format. If opting for the default these "themConfig" block can be removed
      # "hh:mm AP" = 08:00 PM
      # "HH:mm"    = 20:00
      HourFormat = "hh:mm AP";
      #DateFormat = ""; # "Some theme may not support this. Commmented because i like the default but kept for reference
    };
  };
in
{

  services.xserver.enable = true;
  services.xserver = {
    excludePackages = [ pkgs.xterm ];
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";

    # Dependencies go here so SDDM can load them
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };

  # Theme goes here so it links to /run/current-system/sw/share/sddm/themes
  environment.systemPackages = [
    sddmTheme
    pkgs.bibata-cursors
  ];

  services.displayManager.autoLogin = {
    enable = false;
    user = vars.user;
  };

  services.displayManager.defaultSession = lib.mkIf vars.hyprland "hyprland-uwsm";
  services.getty.autologinUser = null;
}
```


# ~nixOS/nixos/modules/user.nix

This file defines the **Base Layer** for user configuration. It sets the absolute minimum requirements for a usable user account, regardless of which physical machine the system is running on.

---

## Key Concepts

### 1. The "Safety Net" (Why configure groups twice?)

You might notice that `extraGroups` (permissions) are defined here **and** in the machine-specific `configuration.nix`. This is intentional.

* **Fail-Safe Mechanism:** This file acts as a safety net. If you accidentally delete or break the user configuration in your host file, this module ensures your user **always** has:
* `wheel`: Administrative privileges (`sudo`) to fix the system.
* `networkmanager`: Internet access to download fixes.

**Merging:** Nix automatically combines these groups with the machine-specific ones (like `docker` or `video`) defined in `configuration.nix`.



### 2. Global Shell Enforcement

It set the default shell based on what the user choose as a variable

---

## The Code

```nix
{ pkgs, vars, ... }:
let
  # 🛡️ FALLBACK: Defaults to "zsh" if vars.shell is missing
  currentShell = vars.shell or "zsh";

  shellPkg =
    if currentShell == "fish" then
      pkgs.fish
    else if currentShell == "zsh" then
      pkgs.zsh
    else
      pkgs.bashInteractive;
in
{
  programs.zsh.enable = currentShell == "zsh";
  programs.fish.enable = currentShell == "fish";

  # Currently the user can run some sudo commands without a password
  # To require a password, uncomment the following line
  #security.sudo.wheelNeedsPassword = true;

  users = {
    defaultUserShell = shellPkg;
    users.${vars.user} = {
      isNormalUser = true;
      shell = shellPkg;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };
}
```

