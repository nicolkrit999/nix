- [~nixOS/flake.nix](#nixosflakenix)
  - [Key Concepts](#key-concepts)
    - [1. The "Two-Pass" Build System](#1-the-two-pass-build-system)
    - [2. Dynamic Variable Merging vs. Module Loading](#2-dynamic-variable-merging-vs-module-loading)
    - [3. Safety Fallbacks](#3-safety-fallbacks)
  - [The Code](#the-code)
- [~nixOS/home-manager/home.nix](#nixoshome-managerhomenix)
  - [Key Concepts](#key-concepts-1)
    - [1. User Identity \& State Version](#1-user-identity--state-version)
    - [2. Modular Architecture](#2-modular-architecture)
    - [3. XDG Integration \& KDE Fixes](#3-xdg-integration--kde-fixes)
    - [4. Imperative Actions (Activation Scripts)](#4-imperative-actions-activation-scripts)
  - [The Code](#the-code-1)
- [~nixOS/home-manager/home-packages.nix](#nixoshome-managerhome-packagesnix)
  - [Key Concepts](#key-concepts-2)
    - [1. Dynamic Selection](#1-dynamic-selection)
    - [2. Global vs. Host-Specific](#2-global-vs-host-specific)
    - [3. Critical Dependencies](#3-critical-dependencies)
- [~nixOS/home-manager/modules/gnome/gnome-main.nix](#nixoshome-managermodulesgnomegnome-mainnix)
  - [Key Concepts](#key-concepts-3)
    - [1. Wallpaper Handling (Single Monitor Focus)](#1-wallpaper-handling-single-monitor-focus)
    - [2. Adaptive Theming (Polarity)](#2-adaptive-theming-polarity)
    - [3. Dconf Overrides](#3-dconf-overrides)
  - [The Code](#the-code-2)
- [~nixOS/home-manager/modules/hyprland/hyprland-main.nix](#nixoshome-managermoduleshyprlandhyprland-mainnix)
  - [Key Concepts](#key-concepts-4)
    - [1. Dynamic Monitor Configuration](#1-dynamic-monitor-configuration)
    - [2. Theming Bridge (Catppuccin vs. Stylix)](#2-theming-bridge-catppuccin-vs-stylix)
    - [3. Environment \& Compatibility](#3-environment--compatibility)
    - [4. Smart Rules](#4-smart-rules)
  - [The Code](#the-code-3)
- [~nixOS/home-manager/modules/kde/kde-main.nix](#nixoshome-managermoduleskdekde-mainnix)
  - [Key Concepts](#key-concepts-5)
    - [1. Multi-Monitor Wallpapers](#1-multi-monitor-wallpapers)
    - [2. Dynamic Theme Construction](#2-dynamic-theme-construction)
    - [3. Config Overrides](#3-config-overrides)
  - [The Code](#the-code-4)
- [~nixOS/home-manager/modules/waybar/default.nix](#nixoshome-managermoduleswaybardefaultnix)
  - [Key Concepts](#key-concepts-6)
    - [1. Hybrid Theming (CSS + Nix Variables)](#1-hybrid-theming-css--nix-variables)
    - [2. Host-Specific Customization](#2-host-specific-customization)
    - [3. Dynamic Weather Script](#3-dynamic-weather-script)
  - [The Code](#the-code-5)
- [~nixOS/home-manager/modules/wofi/default.nix](#nixoshome-managermoduleswofidefaultnix)
  - [Key Concepts](#key-concepts-7)
    - [1. Manual Palette Definition](#1-manual-palette-definition)
    - [2. Hybrid Theming Strategy (Semantic Mapping)](#2-hybrid-theming-strategy-semantic-mapping)
    - [3. CSS Injection](#3-css-injection)
  - [The Code](#the-code-6)
- [~nixOS/home-manager/modules/alacritty.nix](#nixoshome-managermodulesalacrittynix)
  - [Key Concepts](#key-concepts-8)
    - [1. Smart Font Scaling](#1-smart-font-scaling)
    - [2. Robust Resolution Parsing](#2-robust-resolution-parsing)
    - [3. Theming](#3-theming)
  - [The Code](#the-code-7)
- [~nixOS/home-manager/modules/firefox.nix](#nixoshome-managermodulesfirefoxnix)
  - [Key Concepts](#key-concepts-9)
    - [1. Extension Management](#1-extension-management)
    - [2. `about:config` Automation](#2-aboutconfig-automation)
    - [3. Toolbar Layout (JSON)](#3-toolbar-layout-json)
    - [4. Search Configuration](#4-search-configuration)
  - [The Code](#the-code-8)
- [~nixOS/home-manager/modules/kitty.nix](#nixoshome-managermoduleskittynix)
  - [Key Concepts](#key-concepts-10)
    - [1. Smart Font Scaling](#1-smart-font-scaling-1)
    - [2. Theming \& Overrides](#2-theming--overrides)
    - [3. Usability Tweaks](#3-usability-tweaks)
  - [The Code](#the-code-9)
- [~nixOS/home-manager/modules/qt.nix](#nixoshome-managermodulesqtnix)
  - [Key Concepts](#key-concepts-11)
    - [1. The "Delicate" Balance (Preventing KDE Crashes)](#1-the-delicate-balance-preventing-kde-crashes)
    - [2. The Engine: Kvantum](#2-the-engine-kvantum)
    - [3. Dynamic Theme Selection](#3-dynamic-theme-selection)
  - [The Code](#the-code-10)
- [~nixOS/home-manager/modules/stylix.nix](#nixoshome-managermodulesstylixnix)
  - [Key Concepts](#key-concepts-12)
    - [1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)](#1-the-traffic-cop-strategy-catppuccin-vs-base16)
    - [2. Preventing Desktop Crashes (The Qt/KDE Conflict)](#2-preventing-desktop-crashes-the-qtkde-conflict)
    - [3. Global Assets](#3-global-assets)
  - [The Code](#the-code-11)
- [~nixOS/home-manager/modules/zsh.nix](#nixoshome-managermoduleszshnix)
  - [Key Concepts](#key-concepts-13)
    - [1. Smart Rebuild Aliases (Impure vs. Pure)](#1-smart-rebuild-aliases-impure-vs-pure)
    - [2. Hybrid Configuration (`.zshrc_custom`)](#2-hybrid-configuration-zshrc_custom)
    - [3. The Startup Sequence](#3-the-startup-sequence)
  - [The Code](#the-code-12)
- [~nixOS/hosts/template-host/configuration.nix](#nixoshoststemplate-hostconfigurationnix)
  - [Key Concepts](#key-concepts-14)
    - [1. Graphical Stability (Preventing Crashes)](#1-graphical-stability-preventing-crashes)
    - [2. Universal Keyboard Layout](#2-universal-keyboard-layout)
    - [3. User \& Host Identity](#3-user--host-identity)
    - [4. Input Method Cleanup (ibus)](#4-input-method-cleanup-ibus)
  - [The Code](#the-code-13)
- [~nixOS/nixos/modules/boot.nix](#nixosnixosmodulesbootnix)
  - [Key Concepts](#key-concepts-15)
    - [1. GRUB vs. systemd-boot](#1-grub-vs-systemd-boot)
    - [2. Dual Boot Support (`os-prober`)](#2-dual-boot-support-os-prober)
    - [3. UEFI Accessibility](#3-uefi-accessibility)
  - [The Code](#the-code-14)
- [~nixOS/nixos/modules/env.nix](#nixosnixosmodulesenvnix)
  - [Key Concepts](#key-concepts-16)
    - [1. Smart Editor Configuration](#1-smart-editor-configuration)
    - [2. Dynamic Defaults](#2-dynamic-defaults)
    - [3. Path Injection](#3-path-injection)
  - [The Code](#the-code-15)
- [~nixOS/nixos/modules/guest.nix](#nixosnixosmodulesguestnix)
  - [Key Concepts](#key-concepts-17)
    - [1. Ephemeral Home (`tmpfs`)](#1-ephemeral-home-tmpfs)
    - [2. Forced Desktop Environment (XFCE)](#2-forced-desktop-environment-xfce)
    - [3. Security Hardening](#3-security-hardening)
    - [4. User Warning](#4-user-warning)
  - [The Code](#the-code-16)
- [~nixOS/home-manager/modules/mime.nix](#nixoshome-managermodulesmimenix)
  - [Key Concepts](#key-concepts-18)
    - [1. Dynamic Associations](#1-dynamic-associations)
    - [2. Desktop File Translation (`mkDesktop`)](#2-desktop-file-translation-mkdesktop)
  - [The Code](#the-code-17)
- [~nixOS/nixos/modules/nix.nix](#nixosnixosmodulesnixnix)
  - [Key Concepts](#key-concepts-19)
    - [1. Enabling Flakes](#1-enabling-flakes)
    - [2. Binary Caching (Speed)](#2-binary-caching-speed)
    - [3. Automatic Garbage Collection](#3-automatic-garbage-collection)
  - [The Code](#the-code-18)
- [~nixOS/nixos/modules/sddm.nix](#nixosnixosmodulessddmnix)
  - [Key Concepts](#key-concepts-20)
    - [1. The "Astronaut" Theme](#1-the-astronaut-theme)
    - [2. X11 Backend for Stability](#2-x11-backend-for-stability)
    - [3. UWSM Integration](#3-uwsm-integration)
  - [The Code](#the-code-19)
- [~nixOS/nixos/modules/user.nix](#nixosnixosmodulesusernix)
  - [Key Concepts](#key-concepts-21)
    - [1. The "Safety Net" (Why configure groups twice?)](#1-the-safety-net-why-configure-groups-twice)
    - [2. Global Shell Enforcement](#2-global-shell-enforcement)
  - [The Code](#the-code-20)


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

### 3. Safety Fallbacks

In `makeHome`, the `or` operator is used (e.g., `hostVars.kdeMice or []`). This ensures that if a user (like `template-host`) hasn't defined optional variables in `modules.nix`, the build doesn't crash—it just uses a safe default (like an empty list).

---

## The Code

```nix
{
  description = "My personal nixOS configuration with multi-host support";

  # ========================================================================
  # ⬇️ INPUTS
  # ========================================================================
  # These are the external dependencies downloaded from the internet.
  inputs = {
    # The main OS source (Pinned to version 25.11 for stability)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # The "Unstable" source (Used for specific packages that need to be bleeding edge)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # External source for Flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Home Manager: Manages user dotfiles (Must match NixOS version)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs"; # Forces HM to use the version of nixpkgs
    };

    # Stylix: Theming engine (Base16 + Fonts + Wallpapers)
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Firefox Add-ons: Allows installing extensions via Nix
    # If firefox is uninstalled or the user does not want to hardcode extensions than it can be removed
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin: Theming specific modules (like Hyprland/Waybar)
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager: Configure KDE Plasma declaratively
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  # ========================================================================
  # 📤 OUTPUTS
  # ========================================================================
  # This function produces the actual configurations.
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      # 📋 HOST REGISTRY
      # The list of computers this config manages.
      # The folder name in ./hosts/MUST match one of these names.
      hostNames = [
        "template-host" # Reference for new machines
        "nixos-desktop"
        "nixos-laptop"
      ];

      # -------------------------------------------------------------------
      # 🛠️ SYSTEM BUILDER FUNCTION
      # Generates the Root OS Configuration
      # -------------------------------------------------------------------
      makeSystem =
        hostname:
        let
          # 1. Load Mandatory Identity Variables
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Load Optional Power-User Tweaks (modules.nix)
          # Check if file exists; if not, return empty set { } which result in the fallbacks being applied
          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. MERGE CONFIGS
          # 'extraVars' overrides 'baseVars' if there are collisions
          hostVars = baseVars // extraVars;

          # 4. Create an instance of Unstable Packages for this system
          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit (hostVars) system;
          
          # 'specialArgs' passes data to ALL system modules
          specialArgs = {
            inherit inputs pkgs-unstable;
            
            # Pass every variable from hostVars to the modules
            # This allows configuration.nix to see "hostname", "user", etc.
            inherit (hostVars)
              hostname
              system
              user
              stateVersion
              hyprland
              gnome
              kde
              cosmic
              flatpak
              term
              browser
              editor
              fileManager
              base16Theme
              polarity
              catppuccin
              catppuccinFlavor
              catppuccinAccent
              timeZone
              weather
              keyboardLayout
              keyboardVariant
              screenshots
              tailscale
              guest
              zramPercent
              wallpapers
              ;
          };

          modules = [
            # The Main Configuration File
            ./hosts/${hostname}/configuration.nix
            
            # Modules provided by Inputs
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            {
              # Configure Nixpkgs Instance
              nixpkgs.pkgs = import nixpkgs {
                system = hostVars.system;
                config.allowUnfree = true;
              };
              time.timeZone = hostVars.timeZone;
            }
          ]
          # CONDITIONAL MODULES
          # Only import these files if the variable is true in variables.nix
          ++ (nixpkgs.lib.optional (hostVars.hyprland or false) ./nixos/modules/hyprland.nix)
          ++ (nixpkgs.lib.optional (hostVars.gnome or false) ./nixos/modules/gnome.nix)
          ++ (nixpkgs.lib.optional (hostVars.kde or false) ./nixos/modules/kde.nix)
          ++ (nixpkgs.lib.optional (hostVars.cosmic or false) ./nixos/modules/cosmic.nix);
        };

      # -------------------------------------------------------------------
      # 🏠 HOME BUILDER FUNCTION
      # Generates the User Configuration (Home Manager)
      # -------------------------------------------------------------------
      makeHome =
        hostname:
        let
          # (Same Merging Logic as System Builder)
          baseVars = import ./hosts/${hostname}/variables.nix;
          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };
          hostVars = baseVars // extraVars;

          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = hostVars.system;
            config.allowUnfree = true;
          };

          # 'extraSpecialArgs' passes data to ALL Home Manager modules
          extraSpecialArgs = {
            inherit inputs pkgs-unstable;
            
            # Pass standard variables
            inherit (hostVars)
              hostname
              user
              gitUserName
              gitUserEmail
              homeStateVersion
              hyprland
              gnome
              kde
              cosmic
              term
              browser
              editor
              fileManager
              base16Theme
              polarity
              catppuccin
              catppuccinFlavor
              catppuccinAccent
              weather
              keyboardLayout
              keyboardVariant
              screenshots
              monitors
              wallpapers
              idleConfig
              ;

            # 🛡️ SAFE FALLBACKS
            # These variables are defined in modules.nix.
            # If the user didn't create modules.nix, then fallbacks apply (after the or statement)

            # Default to being empty (not defined)
            hyprlandWorkspaces = hostVars.hyprlandWorkspaces or [ ];
            kdeMice = hostVars.kdeMice or [ ];
            kdeTouchpads = hostVars.kdeTouchpads or [ ];
            waybarWorkspaceIcons = hostVars.waybarWorkspaceIcons or { };
            waybarLayoutFlags = hostVars.waybarLayoutFlags or { };
            
            # Defaults to true/false if undefined
            starshipZshIntegration = hostVars.starshipZshIntegration or true;
            nixImpure = hostVars.nixImpure or false;
            hyprlandWindowRules = hostVars.hyprlandWindowRules or [ ];
          };

          modules = [
            # Main Home Manager File
            ./home-manager/home.nix
            
            # Modules provided by Inputs
            inputs.catppuccin.homeModules.catppuccin
            inputs.plasma-manager.homeModules.plasma-manager
            ./home-manager/modules/wofi # This is imported because the application launcher is not de-specific
          ]
          
          # HOST SPECIFIC HOME.NIX
          # If hosts/<name>/home.nix exists, import it. Otherwise do nothing.
          ++ (
            if builtins.pathExists ./hosts/${hostname}/home.nix then [ ./hosts/${hostname}/home.nix ] else [ ]
          )

          # CONDITIONAL HOME MODULES
          # Only enable desktop configs if the desktop is enabled in variables.nix
          ++ (nixpkgs.lib.optionals (hostVars.hyprland or false) [
            ./home-manager/modules/hyprland
            ./home-manager/modules/waybar
            ./home-manager/modules/swaync
          ])
          ++ (nixpkgs.lib.optional (hostVars.gnome or false) ./home-manager/modules/gnome)
          ++ (nixpkgs.lib.optional (hostVars.kde or false) ./home-manager/modules/kde)
          ++ (nixpkgs.lib.optional (hostVars.cosmic or false) ./home-manager/modules/cosmic);
        };
    in
    {
      # 🪄 THE GENERATOR
      # This runs the functions above for EVERY host in the 'hostNames' list.
      # Result: nixosConfigurations."nixos-desktop", nixosConfigurations."template-host", etc.
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames makeSystem;
      homeConfigurations = nixpkgs.lib.genAttrs hostNames makeHome;

      # Formatter definition (allows running 'nix fmt')
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
```


# ~nixOS/home-manager/home.nix

The `home.nix` file is the **root configuration** for Home Manager. While `configuration.nix` manages the *system* (drivers, bootloader, root users), `home.nix` manages the *user* (dotfiles, themes, user-specific packages).

It serves as the foundation upon which your personal environment is built.

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

```nix
{
  pkgs,
  pkgs-unstable,
  term,
  browser,
  fileManager,
  editor,
  ...
}:
let
  # 🛡️ SAFE FALLBACKS for browser, fileManager, editor
  # If the user's choice is invalid or missing, these are installed.
  fallbackTerm = pkgs.kitty;
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

  myTermPkg = getPkg term fallbackTerm;
  myBrowserPkg = getPkg browser fallbackBrowser;
  myFileManagerPkg = getPkg fileManager fallbackFileManager;
  myEditorPkg = getPkg editor fallbackEditor;
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
      pavucontrol # Audio control (Vital for Hyprland)

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      brightnessctl # Control device backlight/brightness (needed for hyprland binds)
      cliphist # Wayland clipboard history manager (needed for clipboard management)
      eza # Modern ls replacement (used in shell and ranger)
      ffmpegthumbnailer # Lightweight video thumbnailer (needed for ranger video previews)
      fzf # Fuzzy finder (used in shell and ranger)
      git # Version control system (used in various scripts)
      grimblast # Wayland screenshot helper for Hyprland (referenced in chromium.nix module)
      htop # Interactive process viewer (keep to kill processes easily)
      hyprpicker # Wayland color picker (needed for hyprland binds)
      nixfmt-rfc-style # Nix code formatter with RFC style (used in flake.nix)
      playerctl # Control MPRIS-enabled media players (Spotify, etc.) (used in hyprland binds)
      showmethekey # Visualizer for keyboard input (used by hyprland binds)
      starship # Shell prompt (used by starship.nix)
      ueberzugpp # Image previews for terminal (used by Ranger backend)
      wl-clipboard # Wayland copy/paste CLI tools (needed for clipboard management)
      zsh-autosuggestions # Fish-like autosuggestions for Zsh (used in zsh config)

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      #

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------
      libnotify # Library for desktop notifications (used by hyprland-notifications)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers (needed for hyprland)
      xdg-desktop-portal-hyprland # Hyprland specific portal for screen sharing (needed for hyprland)

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used by nixos development)

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
  wallpapers,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  polarity,
  base16Theme,
  ...
}:
let
  # 1. GET PRIMARY WALLPAPER
  # GNOME only natively supports one wallpaper for the desktop background.
  # We take the first element (head) of the list defined in variables.nix.
  firstWallpaper = builtins.head wallpapers;
  
  # 2. DOWNLOAD WALLPAPER
  # Fetch the image file into the Nix store so it is available locally.
  wallpaperPath = pkgs.fetchurl {
    url = firstWallpaper.wallpaperURL;
    sha256 = firstWallpaper.wallpaperSHA256;
  };

  # 3. DETERMINE THEME SETTINGS
  # Translate "polarity" variable into GNOME-compatible strings.
  colorScheme = if polarity == "dark" then "prefer-dark" else "prefer-light";
  iconThemeName = if polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  # -----------------------------------------------------------------------
  # 📦 GNOME PACKAGES
  # -----------------------------------------------------------------------
  home.packages =
    # Conditionally install Catppuccin GTK theme if enabled in variables.nix
    (lib.optionals catppuccin [
      (pkgs.catppuccin-gtk.override {
        accents = [ catppuccinAccent ];
        size = "standard";
        tweaks = [
          "rimless"
          "black"
        ];
        variant = catppuccinFlavor;
      })
    ])
    
    # Standard GNOME Tools & Icons
    ++ [
      pkgs.papirus-icon-theme
      pkgs.hydrapaper # Useful for multi-monitor wallpaper management if needed manually
    ];

  # -----------------------------------------------------------------------
  # ⚙️ DCONF SETTINGS (The "Registry")
  # -----------------------------------------------------------------------
  dconf.settings = {

    # --- INTERFACE & THEME ---
    "org/gnome/desktop/interface" = {
      # Forces Dark/Light mode based on variables.nix
      color-scheme = lib.mkForce colorScheme;
      icon-theme = iconThemeName;
    };

    # --- WALLPAPER ---
    "org/gnome/desktop/background" = {
      # Sets the background to the file in the Nix Store
      picture-uri = "file://${wallpaperPath}";
      picture-uri-dark = "file://${wallpaperPath}";
      picture-options = lib.mkForce "zoom";
    };

    # --- LOCK SCREEN ---
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${wallpaperPath}";
    };

    # --- WINDOW MANAGER ---
    # GNOME hides minimize/maximize by default. We bring them back.
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
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
  screenshots,
  monitors,
  keyboardLayout,
  keyboardVariant,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  term,
  hyprlandWorkspaces,
  ...
}:
{
  # ----------------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # ----------------------------------------------------------------------------
  # If enabled in variables.nix, this activates the official Hyprland module
  catppuccin.hyprland.enable = catppuccin;
  catppuccin.hyprland.flavor = catppuccinFlavor;
  catppuccin.hyprland.accent = catppuccinAccent;

  # ----------------------------------------------------------------------------
  # ⚙️ HYPRLAND CONFIGURATION
  # ----------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true; # Improves stability and integration with systemd services

    settings = {

      # -----------------------------------------------------
      # 🌍 ENVIRONMENT VARIABLES
      # -----------------------------------------------------
      # Critical for app compatibility on Wayland
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
        "XDG_SCREENSHOTS_DIR,${screenshots}" # Tells tools where to save screenshots by default.
      ];

      # -----------------------------------------------------
      # 🖥️ MONITOR CONFIGURATION
      # -----------------------------------------------------
      # Merges the host-specific list with a safe fallback
      monitor = monitors ++ [
        ",preferred,auto,1" 
      ];

      # -----------------------------------------------------
      # 🎛️ VARIABLES & APPS
      # -----------------------------------------------------
      "$mainMod" = "SUPER"; # The Windows key
      "$term" = term;       # Pulls the terminal defined in variables.nix
      "$fileManager" = "$term -e sh -c 'ranger'"; # Console file manager
      "$menu" = "wofi";     # Application launcher

      # -----------------------------------------------------
      # 🚀 STARTUP APPS (Exec-Once)
      # -----------------------------------------------------
      exec-once = [
        "waybar" # Status bar
        "wl-paste --type text --watch cliphist store"  # Clipboard history (Text)
        "wl-paste --type image --watch cliphist store" # Clipboard history (Images)
        "pkill ibus-daemon" # Kill ibus given by gnome
      ];

      # -----------------------------------------------------
      # 🎨 LOOK & FEEL
      # -----------------------------------------------------
      general = {
        gaps_in = 0;      # Inner gaps between windows
        gaps_out = 0;     # Outer gaps (screen edge)
        border_size = 5;  # Thick borders

        # DYNAMIC BORDER COLORS
        # If Catppuccin is active, use its variables. Otherwise, use Stylix Base16 hex codes.
        "col.active_border" = if catppuccin then "$accent" else "rgb(${config.lib.stylix.colors.base0D})";
        "col.inactive_border" = if catppuccin then "$overlay0" else "rgb(${config.lib.stylix.colors.base03})";

        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle"; # Tiling algorithm (Dwindle is the standard spiral)
      };

      decoration = {
        rounding = 0; # Sharp corners
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        
        # Disable heavy effects for performance
        shadow = { enabled = false; };
        blur = { enabled = false; };
      };

      animations = {
        enabled = true;
      };

      # -----------------------------------------------------
      # ⌨️ INPUT
      # -----------------------------------------------------
      # Uses the layout defined in variables.nix
      input = {
        kb_layout = keyboardLayout;
        kb_variant = keyboardVariant;
        kb_options = "grp:alt_shift_toggle"; # Alt+Shift switches layouts if multiple are defined
      };

      # -----------------------------------------------------
      # 📐 LAYOUT SETTINGS (Dwindle)
      # -----------------------------------------------------
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # -----------------------------------------------------
      # 📋 WINDOW RULES (V2)
      # -----------------------------------------------------
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
      ++ hyprlandWindowRules # Force certains apps to certain workspaces if defined in modules.nix

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
      ];

      # -----------------------------------------------------
      # 🗄️ WORKSPACE RULES
      # -----------------------------------------------------
      workspace = [
        "w[tv1], gapsout:0, gapsin:0" # Remove gaps if only 1 window is visible
        "f[1], gapsout:0, gapsin:0"   # Remove gaps if window is fullscreen
      ]
      # Merges the host-specific bindings (e.g., "1, monitor:DP-1")
      ++ hyprlandWorkspaces;
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
  lib,
  wallpapers,
  config,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
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
  ) wallpapers;

  # 2. DETERMINE POLARITY
  # Helper to determine if we are in dark or light mode
  polarity = config.stylix.polarity;

  # 3. HELPER FUNCTION
  # Capitalizes the first letter of a string (mocha -> Mocha)
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  # 4. CONSTRUCT THEME NAME
  # Builds the exact theme string required by KDE (e.g., "CatppuccinMochaSky")
  theme =
    if catppuccin then
      "Catppuccin${capitalize catppuccinFlavor}${capitalize catppuccinAccent}"
    else if polarity == "dark" then
      "BreezeDark"
    else
      "BreezeLight";

  # 5. LOOK AND FEEL
  # Determines the global "skin" (panels, OSDs, layout).
  # We rely on the 'polarity' variable to decide between Breeze Dark or Light.
  # This works for both Catppuccin (Latte=Light, Mocha=Dark) and standard themes.
  lookAndFeel = 
    if polarity == "dark" then 
      "org.kde.breezedark.desktop" 
    else 
      "org.kde.breeze.desktop";

  cursorTheme = config.stylix.cursor.name;
in
{

  # Kill plasma
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
      "kdeglobals"."KDE"."widgetStyle" = if catppuccin then "kvantum" else "Breeze";
      "kdeglobals"."General"."AccentColor" = if catppuccin then "203,166,247" else null; # Manual mauve fallback
    };
  };

  # -----------------------------------------------------------------------
  # 📦 KDE PACKAGES
  # -----------------------------------------------------------------------
  # Apps installed only when KDE is the active desktop
  home.packages = with pkgs.kdePackages;
  [
    kcalc
    kcolorchooser
    elisa      # Music Player
    gwenview   # Image Viewer
    okular     # PDF Viewer
    konsole    # Terminal

    # Theme dependencies
    pkgs.catppuccin-kde
    pkgs.catppuccin-kvantum
  ];
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
  weather,
  catppuccin,
  catppuccinAccent,
  waybarWorkspaceIcons,
  waybarLayoutFlags,
  ...
}:
let
  # 1. READ EXTERNAL CSS
  # Loads the static layout rules (margins, padding, border-radius)
  cssContent = builtins.readFile ./style.css;

  # 2. GENERATE DYNAMIC COLORS
  # Creates a block of CSS variables based on the current system theme.
  cssVariables =
    if catppuccin then
      ''
        @define-color accent @${catppuccinAccent};
      ''
    else
      ''
        /* 🔴 BASE16 FALLBACK MODE */
        /* Maps generic hex codes (base00-base0F) to readable names */
        @define-color base   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color text   ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */
        @define-color accent ${config.lib.stylix.colors.withHashtag.base0D}; /* Default Accent */

        @define-color red    ${config.lib.stylix.colors.withHashtag.base08};
        @define-color peach  ${config.lib.stylix.colors.withHashtag.base09}; /* Orange */
        @define-color green  ${config.lib.stylix.colors.withHashtag.base0B};
        @define-color teal   ${config.lib.stylix.colors.withHashtag.base0C}; /* Cyan */
        @define-color blue   ${config.lib.stylix.colors.withHashtag.base0D};
        @define-color mauve  ${config.lib.stylix.colors.withHashtag.base0E}; /* Purple */
      '';

in
{
  # Enable official Catppuccin integration if the flag is true
  catppuccin.waybar.enable = catppuccin;

  programs.waybar = {
    enable = true;

    # -----------------------------------------------------------------------
    # 🎨 STYLE CONFIGURATION
    # -----------------------------------------------------------------------
    # Injects the dynamic variables BEFORE the static CSS content
    style = lib.mkAfter ''
      ${cssVariables}
      ${cssContent}
    '';

    settings = {
      mainBar = {
        layer = "top";      # "top" layer puts it above normal windows
        position = "top";   # Position on screen
        height = 40;        # Height in pixels

        # Module Placement Order
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
        # 🗄️ WORKSPACES MODULE
        # -----------------------------------------------------
        "hyprland/workspaces" = {
          disable-scroll = true;
          show-special = true;         # Show scratchpads
          special-visible-only = true; # Only if they are actually open
          all-outputs = false;         # Only show workspaces on the current monitor

          # Format: "{name} {icon}"
          format = "{name} {icon}";
          
          # DYNAMIC ICONS
          # Uses the list defined in host-specific modules.nix
          format-icons = waybarWorkspaceIcons;
        };

        # -----------------------------------------------------
        # ⌨️ LANGUAGE MODULE
        # -----------------------------------------------------
        "hyprland/language" = {
          min-length = 5; # Prevents layout jumping when the flag changes
          tooltip = true;
        }
        # DYNAMIC FLAGS
        # Merges the flags defined in host-specific modules.nix
        // waybarLayoutFlags;

        # -----------------------------------------------------
        # ☁️ WEATHER MODULE
        # -----------------------------------------------------
        "custom/weather" = {
          format = " {} ";
          # Fetches weather for the city defined in variables.nix
          # %c = Condition icon, %t = Temperature
          exec = "curl -s 'wttr.in/${weather}?format=%c%t'";
          interval = 300; # Update every 5 minutes
          class = "weather";
        };

        # -----------------------------------------------------
        # 🔊 AUDIO VOLUME (PulseAudio)
        # -----------------------------------------------------
        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% ";
          format-muted = "";
          format-icons = {
            "headphones" = "";
            "handsfree" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" ];
          };
          on-click = "pavucontrol"; # Open volume mixer on click
        };

        # -----------------------------------------------------
        # 🔋 BATTERY STATUS
        # -----------------------------------------------------
        "battery" = {
          states = {
            warning = 20;  # Yellow at 20%
            critical = 5;  # Red at 5%
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-alt = "{time} {icon}"; # Click to toggle Time Remaining
          format-icons = [ "" "" "" "" "" ];
        };

        # -----------------------------------------------------
        # 🕒 CLOCK & CALENDAR
        # -----------------------------------------------------
        "clock" = {
          format = "{:%m/%d/%Y - %I:%M %p}";
          # Click to toggle full date format
          format-alt = "{:%A, %B %d at %I:%M %p}";
        };

        # -----------------------------------------------------
        # 📥 SYSTEM TRAY
        # -----------------------------------------------------
        "tray" = {
          icon-size = 20;
          spacing = 1;
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
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  term,
  ...
}:
let
  # 1. READ STATIC CSS
  # Loads the layout rules (margins, borders, etc.) from the external file.
  cssContent = builtins.readFile ./style.css;

  # 2. DEFINE PALETTES MANUALLY
  # Since Wofi needs CSS variables, we hardcode the hex values for all flavors here.
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
      # ... (Hex codes for Macchiato) ...
      base = "#24273a";
      text = "#cad3f5";
      # ...
    };
    frappe = {
      # ... (Hex codes for Frappe) ...
      base = "#303446";
      text = "#c6d0f5";
      # ...
    };
    latte = {
      # ... (Hex codes for Latte) ...
      base = "#eff1f5";
      text = "#4c4f69";
      # ...
    };
  };

  # 3. SELECT PALETTE
  # Grabs the correct set of colors based on the user's variable
  selectedPalette = palettes.${catppuccinFlavor};

  # 4. GENERATE CSS VARIABLES
  cssVariables =
    if catppuccin then
      ''
        /* 🎨 CATPPUCCIN MODE */
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
        @define-color accent      @${catppuccinAccent}; /* User-selected accent */
        @define-color window_bg   @base;
        @define-color input_bg    @surface0;
        @define-color selected_bg @surface1;
        @define-color text_color  @text;
      ''
    else
      ''
        /* 🔴 BASE16 FALLBACK MODE */
        /* Map generic Base16 hex codes to the same semantic names */
        @define-color window_bg   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color input_bg    ${config.lib.stylix.colors.withHashtag.base01}; /* Lighter */
        @define-color selected_bg ${config.lib.stylix.colors.withHashtag.base02}; /* Selection */
        @define-color text        ${config.lib.stylix.colors.withHashtag.base05};
        @define-color text_color  ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */
        @define-color accent      ${config.lib.stylix.colors.withHashtag.base0D}; /* Blue/Accent */
      '';
in
{
  programs.wofi = {
    enable = true;
    
    settings = {
      show = "drun";        # Run application mode
      width = 950;
      height = 500;
      always_parse_args = true;
      show_all = false;
      term = term;          # Use the terminal from variables.nix
      hide_scroll = true;
      print_command = true;
      insensitive = true;   # Case insensitive search
      prompt = "";
      columns = 2;          # 2-column grid layout
      allow_markup = true;
      allow_images = true;  # Show app icons
    };

    # -----------------------------------------------------------------------
    # 🎨 APPLY STYLES
    # -----------------------------------------------------------------------
    # Injects the calculated variables BEFORE the content of style.css
    style = ''
      ${cssVariables}
      ${cssContent}
    '';
  };
}
```


# ~nixOS/home-manager/modules/alacritty.nix

This file configures **Alacritty**, a GPU-accelerated terminal emulator known for its speed. While Alacritty configuration is usually straightforward, this module adds a layer of **intelligence** to handle different hardware setups automatically.

---

## Key Concepts

### 1. Smart Font Scaling

One of the biggest pain points when switching between a Laptop (1080p) and a Desktop (4K) is that font sizes don't scale linearly. Text that looks good on 1080p is microscopic on 4K.

* **The Solution:** This module parses your `monitors` variable (from `variables.nix`) to determine the primary screen's resolution.
* **The Logic:**
* If Width > 3000 (4K): Sets font size to **16.0**.
* If Width > 2000 (1440p): Sets font size to **13.0**.
* Otherwise (1080p): Sets font size to **11.0**.



### 2. Robust Resolution Parsing

Nix strings can be tricky. The code includes multiple safety checks to ensure the build never fails, even if you define monitors weirdly or leave the list empty.

* It filters out disabled monitors.
* It splits the monitor definition string (e.g., `"DP-1, 3840x2160@144, 0x0, 1"`) to extract the resolution.
* It splits the resolution (`3840x2160`) to get the width.
* It checks if the result is actually a number before doing math.

### 3. Theming

* **Catppuccin:** If enabled, it uses the official module to apply the flavor (Mocha/Latte).
* **Stylix Override:** We use `lib.mkForce` for the font size. This tells Nix: "Ignore the global font size set by Stylix; use my calculated smart size instead."

---

## The Code

```nix
{
  lib,
  inputs,
  monitors,
  catppuccin,
  catppuccinFlavor,
  ...
}:

let
  # -----------------------------------------------------------------------
  # 📐 RESOLUTION PARSING LOGIC
  # -----------------------------------------------------------------------
  
  # 1. Filter out monitors that are explicitly disabled in variables.nix
  enabledMonitors = builtins.filter (m: builtins.match ".*disable.*" m == null) monitors;

  # 2. Get the Primary Monitor (First one in the list)
  # Fallback to empty string if the list is empty (headless mode / install)
  primaryMonitor = if builtins.length enabledMonitors > 0 then builtins.head enabledMonitors else "";

  # 3. Extract Resolution Block
  # Input format: "PORT, RESOLUTION@HZ, POS, SCALE"
  # We split by "," and take the second part (Index 1)
  parts = lib.splitString "," primaryMonitor;
  resolutionBlock = if builtins.length parts > 1 then builtins.elemAt parts 1 else "";

  # 4. Extract Width
  # Input format: "3840x2160"
  # We split by "x" and take the first part
  widthList = lib.splitString "x" resolutionBlock;
  widthStr = if builtins.length widthList > 0 then builtins.head widthList else "";

  # 5. Safe Conversion to Integer
  # Regex check: Is it composed only of numbers 0-9?
  isNumber = builtins.match "[0-9]+" widthStr != null;
  # If valid, convert to Int. If invalid (or empty), default to 1920 (Standard 1080p).
  width = if isNumber then lib.toInt widthStr else 1920;

  # 6. Calculate Font Size
  smartFontSize =
    if width > 3000 then
      16.0 # 4K Monitors
    else if width > 2000 then
      13.0 # 1440p Monitors
    else
      11.0; # 1080p / Laptops

in
{
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -----------------------------------------------------------------------
  catppuccin.alacritty.enable = catppuccin;
  catppuccin.alacritty.flavor = catppuccinFlavor;

  programs.alacritty = {
    enable = true;
    
    settings = {
      window.opacity = 1.0;

      font = {
        # FORCE the calculated size
        # We use mkForce to override any defaults set by global themes (Stylix)
        size = lib.mkForce smartFontSize;
        
        builtin_box_drawing = true;
        
        # Force Bold style for better readability
        normal = {
          style = lib.mkForce "Bold";
        };
      };
    };
  };
}
```

# ~nixOS/home-manager/modules/firefox.nix

This file configures **Firefox** declaratively. Instead of manually installing extensions and tweaking `about:config` settings on every new install, this module defines the entire browser state in code. It handles everything from the search engine and homepage to privacy extensions and UI customization.

---

## Key Concepts

### 1. Extension Management

We use the `firefox-addons` input (from Rycee's NUR repo) to install extensions declaratively.

* **The Problem:** Normal Firefox installs extensions into a "profile" folder that changes names.
* **The Solution:** Nix installs extensions into a fixed system location, and Firefox loads them automatically.
* **Selection:** The list includes privacy tools (uBlock Origin, Privacy Badger), productivity aids (OneTab, Multi-Account Containers), and integrations (Proton Pass/SimpleLogin).

### 2. `about:config` Automation

The `settings` block maps directly to Firefox's internal configuration registry (`about:config`).

* **Telemetry:** We aggressively disable Mozilla's data collection, crash reporting, and "studies" to enhance privacy.
* **UI Tweaks:** We enable the new **Vertical Tabs** sidebar (`sidebar.verticalTabs`), remove the "Pocket" integration, and clean up the new tab page.
* **Hardening:** Features like `privacy.trackingprotection.enabled` and HTTPS-only mode are forced on by default.

### 3. Toolbar Layout (JSON)

Firefox stores its UI layout (button positions) as a JSON string.

* **Logic:** We construct a Nix attribute set representing the toolbar layout (placing buttons like Back, Forward, URL bar, and specific extension icons) and convert it to a string using `builtins.toJSON`.
* **Result:** This ensures that every time you reinstall, your buttons (like OneTab or Proton Pass) are exactly where you expect them to be, without needing manual dragging and dropping.

### 4. Search Configuration

We define a custom search order:

1. **Google (Default):** For general queries.
2. **Kagi (Private Default):** A premium, privacy-focused search engine used in private windows.
3. **Bing:** Hidden completely.

---

## The Code
This code is my personal one, but it may be change heavily based on your preferences

```nix
{
  pkgs,
  lib,
  inputs,
  user,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  ...
}:
let
  # 1. PREPARE ADDONS
  # Import the collection of Firefox extensions from the flake input
  firefox-addons = pkgs.callPackage inputs.firefox-addons { };
in
{
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -----------------------------------------------------------------------
  # Uses the official module to theme the browser chrome (UI)
  catppuccin.firefox.enable = catppuccin;
  catppuccin.firefox.flavor = catppuccinFlavor;
  catppuccin.firefox.accent = catppuccinAccent;

  # -----------------------------------------------------------------------
  # 🔑 PASSWORD MANAGER
  # -----------------------------------------------------------------------
  # Integration for 'browserpass' (currently disabled in favor of Proton Pass)
  programs.browserpass.enable = false;

  # -----------------------------------------------------------------------
  # 🦊 FIREFOX CONFIGURATION
  # -----------------------------------------------------------------------
  programs.firefox = {
    enable = true;

    profiles.${user} = {
      
      # 🔍 SEARCH ENGINE SETTINGS
      search = {
        force = true; # Prevents Firefox from overriding these settings
        default = "google";
        privateDefault = "kagi"; # Use Kagi for private windows
        
        order = [
          "google"
          "kagi"
          "ddg"
        ];

        engines = {
          kagi = {
            name = "Kagi";
            urls = [ { template = "https://kagi.com/search?q={searchTerms}"; } ];
            icon = "https://kagi.com/favicon.ico";
          };
          bing.metaData.hidden = true; # Hide Bing
        };
      };

      # 📑 BOOKMARKS (Managed declaratively if needed, currently empty)
      bookmarks = { };

      # 🧩 EXTENSIONS
      # Installs extensions from the Nix store
      extensions = {
        force = true; # Allow extensions to modify browser theme
        packages = with firefox-addons; [
          ublock-origin             # Ad blocker
          proton-pass               # Password Manager
          firefox-color             # Theming helper
          sponsorblock              # YouTube sponsor skipper
          gesturefy                 # Mouse gestures
          privacy-badger            # Tracker blocker
          screenshot-capture-annotate
          multi-account-containers  # Work/Personal isolation
          behind-the-overlay-revival # Popup killer
          onetab                    # Tab management
          simplelogin               # Email aliases
        ];
      };

      # ⚙️ INTERNAL SETTINGS (about:config)
      settings = {
        # --- HOMEPAGE & STARTUP ---
        "browser.startup.homepage" = "https://glance.nicolkrit.ch";
        "browser.startup.page" = 1; # Start with homepage

        # --- ANNOYANCE REMOVAL ---
        "browser.disableResetPrompt" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.uitour.enabled" = false; # Disable feature tours
        "browser.download.useDownloadDir" = false; # Always ask where to save
        
        # Clean up New Tab Page (Remove sponsored tiles, pocket, snippets)
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;

        # --- TELEMETRY (PRIVACY) ---
        # Disable all reporting to Mozilla
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "browser.discovery.enabled" = false;

        # --- SECURITY & HARDENING ---
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "signon.rememberSignons" = false; # Disable built-in password manager

        # --- UI LAYOUT ---
        "browser.tabs.inTitlebar" = 0;
        "sidebar.verticalTabs" = true; # Enable new Sidebar API
        "sidebar.revamp" = true;
        "sidebar.main.tools" = [ "history" "bookmarks" ];

        # --- TOOLBAR CONFIGURATION (JSON) ---
        # Places icons exactly where we want them
        "browser.uiCustomization.state" = builtins.toJSON {
          currentVersion = 23;
          newElementCount = 10;
          placements = {
            unified-extensions-area = [ ];
            widget-overflow-fixed-list = [ ];
            
            # The Main Toolbar
            nav-bar = [
              "back-button"
              "forward-button"
              "vertical-spacer"
              "stop-reload-button"
              "urlbar-container"
              "downloads-button"
              
              # Extensions
              "_testpilot-containers-browser-action"
              "reset-pbm-toolbar-button"
              "extension_one-tab_com-browser-action"
              "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action"
              "78272b6fa58f4a1abaac99321d503a20_proton_me-browser-action"
              "addon_simplelogin-browser-action"
              "jid1-mnnxcxisbpnsxq_jetpack-browser-action"

              "unified-extensions-button"
            ];
            
            # Sidebar & Menus
            toolbar-menubar = [ "menubar-items" ];
            vertical-tabs = [ "tabbrowser-tabs" ];
            PersonalToolbar = [ "personal-bookmarks" ];
          };
        };
      };
    };
  };

  # -----------------------------------------------------------------------
  # 🖥️ DEFAULT ASSOCIATIONS
  # -----------------------------------------------------------------------
  # Tells the OS to open HTTP/HTML links with Firefox
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
```


# ~nixOS/home-manager/modules/kitty.nix

This file configures **Kitty**, a fast, GPU-accelerated terminal emulator known for its rich feature set. Like the Alacritty module, this configuration implements **Smart Font Scaling** to ensure text is legible across different monitor resolutions (1080p vs. 4K) without manual intervention.

---

## Key Concepts

### 1. Smart Font Scaling

One of the biggest pain points when switching between a Laptop (1080p) and a Desktop (4K) is that font sizes don't scale linearly. Text that looks good on 1080p is microscopic on 4K.

* **The Solution:** This module parses your `monitors` variable (from `variables.nix`) to determine the primary screen's resolution.
* **The Logic:**
* If Width > 3000 (4K): Sets font size to **16.0**.
* If Width > 2000 (1440p): Sets font size to **13.0**.
* Otherwise (1080p): Sets font size to **11.0**.

### 2. Theming & Overrides


**Catppuccin Integration:** If the `catppuccin` variable is true, we enable the official Kitty module to apply the selected flavor (Mocha, Latte, etc.) automatically.


**Forced Opacity:** We use `lib.mkForce "1.0"` to ensure the background is fully opaque, overriding any global transparency settings that might be applied by Stylix or other theme engines. This is often preferred for readability in coding environments.



### 3. Usability Tweaks

We apply several "quality of life" settings by default:

`copy_on_select = "yes"`: Selecting text automatically copies it to the clipboard (Linux standard behavior).

`confirm_os_window_close = 0`: Disables the annoying "Are you sure?" prompt when closing a window.

`enable_audio_bell = false`: Silences the terminal beep.


---

## The Code

```nix
{
  lib,
  pkgs,
  monitors,
  catppuccin,
  catppuccinFlavor,
  term,
  ...
}:

let
  # -----------------------------------------------------------------------
  # 📐 RESOLUTION PARSING LOGIC (Identical to Alacritty)
  # -----------------------------------------------------------------------
  
  # 1. Filter out disabled monitors
  enabledMonitors = builtins.filter (m: builtins.match ".*disable.*" m == null) monitors;

  # 2. Identify Primary Monitor
  primaryMonitor = if builtins.length enabledMonitors > 0 then builtins.head enabledMonitors else "";

  # 3. Extract Resolution Information
  # format: "PORT, WIDTHxHEIGHT@HZ, POS, SCALE"
  parts = lib.splitString "," primaryMonitor;
  resolutionBlock = if builtins.length parts > 1 then builtins.elemAt parts 1 else "";

  # 4. Extract Width Integer
  widthList = lib.splitString "x" resolutionBlock;
  widthStr = if builtins.length widthList > 0 then builtins.head widthList else "";
  
  # 5. Validation & Conversion
  isNumber = builtins.match "[0-9]+" widthStr != null;
  width = if isNumber then lib.toInt widthStr else 1920; # Default to 1080p width

  # 6. Calculate Font Size
  smartFontSize =
    if width > 3000 then
      16.0 # 4K
    else if width > 2000 then
      13.0 # 1440p
    else
      11.0; # 1080p

in
{
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -----------------------------------------------------------------------
  catppuccin.kitty.enable = catppuccin;
  catppuccin.kitty.flavor = catppuccinFlavor;

  # -----------------------------------------------------------------------
  # 🐱 KITTY CONFIGURATION
  # -----------------------------------------------------------------------
  programs.kitty = {
    enable = true;

    settings = {
      # APPEARANCE
      font_family = "JetBrainsMono Nerd Font";
      font_size = lib.mkForce smartFontSize;   # Apply smart scaling
      background_opacity = lib.mkForce "1.0";  # Force solid background
      window_padding_width = 4;                # Small internal border

      # BEHAVIOR
      copy_on_select = "yes";       # Auto-copy to clipboard on selection
      confirm_os_window_close = 0;  # Disable exit confirmation
      enable_audio_bell = false;    # Silence the bell
      mouse_hide_wait = "3.0";      # Hide cursor after 3s of inactivity
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
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  polarity,
  ...
}:

# ⚠️ DELICATE FILE WARNING
# This file bridges the gap between Stylix, Catppuccin, Hyprland, and KDE.
# Modifying the environment variables incorrectly can cause KDE Plasma to fail at login.
let
  # Helper to Capitalize strings (needed because Catppuccin folders use "Mocha" not "mocha")
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  # 1. DETERMINE KVANTUM THEME
  # Calculates the exact string name of the theme file Kvantum should load.
  kvantumTheme =
    if catppuccin then
      "Catppuccin-${capitalize catppuccinFlavor}-${capitalize catppuccinAccent}"
    else if polarity == "dark" then
      "KvGnomeDark" # High quality dark theme included in Kvantum
    else
      "KvFlatLight"; # High quality light theme included in Kvantum

  # Select Icon Theme based on polarity
  iconThemeName = if polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  config = lib.mkMerge [
    {
      home.sessionVariables = {
        # Force Qt apps to use Wayland, fallback to X11 if unavailable
        QT_QPA_PLATFORM = "wayland;xcb";
        
        # Sets the basic control style (buttons, tabs) to KDE's desktop style
        QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";

        # 🚨 CRITICAL: DO NOT SET 'QT_QPA_PLATFORMTHEME' HERE!
        # - Hyprland sets this variable in its own module.
        # - KDE Plasma sets this variable internally.
        # If you set it here, it conflicts with KDE's internal manager, causing the desktop to crash.
      };

      # 📦 PACKAGES
      # Installs the tools needed to bridge Qt to our config
      home.packages =
        with pkgs;
        [
          libsForQt5.qt5ct              # Config tool for Qt5
          kdePackages.qt6ct             # Config tool for Qt6
          libsForQt5.qtstyleplugin-kvantum # The Kvantum engine (Qt5)
          kdePackages.qtstyleplugin-kvantum # The Kvantum engine (Qt6)
          pkgs.papirus-icon-theme       # Fallback icon theme
        ]
        # Only install the Catppuccin Kvantum theme files if enabled
        ++ (lib.optionals catppuccin [
          pkgs.catppuccin-kvantum
        ]);
    }

    # --- CONFIGURATION FILES ---
    # We generate these files regardless of whether we use Catppuccin or not.
    {
      # 1. Tell Kvantum which theme to use
      xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=${kvantumTheme}
      '';

      # 2. Tell Qt6 to use Kvantum and our Icon Theme
      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';

      # 3. Tell Qt5 to use Kvantum and our Icon Theme
      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';
    }

    # --- CATPPUCCIN SPECIFIC ---
    # If Catppuccin is active, we must manually link the theme folder.
    # Kvantum looks for themes in ~/.config/Kvantum/<theme-name>.
    (lib.mkIf catppuccin {
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
  wallpapers,
  user,
  config,
  polarity,
  base16Theme,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
  ...
}:
let
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;
  
  iconThemeName = if polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  # Import Stylix from Flake Inputs
  imports = [ inputs.stylix.homeModules.stylix ];

  # -----------------------------------------------------------------------
  # 📦 FONTS & ASSETS
  # -----------------------------------------------------------------------
  home.packages = with pkgs; [
    dejavu_fonts              # Classic fallback fonts
    noto-fonts-lgc-plus       # Extended Latin/Greek/Cyrillic
    texlivePackages.hebrew-fonts # Hebrew support
    font-awesome              # Icons for Waybar
    powerline-fonts           # Shell prompt arrows
    powerline-symbols

    # Manually install the GTK theme package so it's available even if Stylix is off
    (catppuccin-gtk.override {
      accents = [ catppuccinAccent ];
      size = "standard";
      tweaks = [ "rimless" "black" ];
      variant = catppuccinFlavor;
    })
  ];

  # -----------------------------------------------------------------------
  # 🎨 STYLIX CONFIGURATION
  # -----------------------------------------------------------------------
  stylix = {
    enable = true;
    polarity = polarity; # "dark" or "light"

    # The Base16 Scheme (The backup theme if Catppuccin is off)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Theme}.yaml";

    # The Wallpaper (Used by Stylix to generate color palettes)
    image = pkgs.fetchurl {
      url = (builtins.head wallpapers).wallpaperURL;
      sha256 = (builtins.head wallpapers).wallpaperSHA256;
    };

    # -----------------------------------------------------------------------
    # 🎯 TARGETS (The "Traffic Cop")
    # -----------------------------------------------------------------------
    # Controls which applications Stylix is allowed to modify.
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

      # ---------------------------------------------------------------------------------------
      # 🎨 GLOBAL CATPPUCCIN
      # Intelligently enable/disable stylix based on whether catppuccin is enabled
      # catppuccin = true -> .enable = false
      # catppuccin = false -> .enable = true
      gtk.enable = !catppuccin; # Avoid .gtkrc-2.0 and gtk-3.0 overrides
      alacritty.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/alacritty.nix
      hyprland.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/main.nix
      hyprlock.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/hyprlock.nix
      swaync.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/swaync/default.nix
      zathura.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/zathura.nix
      bat.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/bat.nix
      lazygit.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/lazygit.nix
      tmux.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/tmux.nix
      starship.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/starship.nix
      cava.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/cava.nix
      kitty.enable = !catppuccin; # Ref: ~/nixOS/home-manager/modules/kitty.nix
      # ---------------------------------------------------------------------------------------

      # Enable stylix but only for certain elements
      firefox.profileNames = [ user ]; # Applies skin only to the defined profile
    };

    # -----------------------------------------------------------------------
    # 🖱️ MOUSE & FONTS (Global)
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

  # -----------------------------------------------------------------------
  # 🛠️ MANUAL GTK OVERRIDES (When Stylix is Disabled)
  # -----------------------------------------------------------------------
  # If Stylix is disabled for GTK (because Catppuccin is ON), we must configure
  # GTK manually here.
  
  # 1. Dconf Settings (GNOME/GTK4)
  dconf.settings = lib.mkIf catppuccin {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce (if polarity == "dark" then "prefer-dark" else "prefer-light");
    };
  };

  # 2. Environment Variables (Legacy)
  home.sessionVariables = lib.mkIf catppuccin {
    GTK_THEME = "catppuccin-${catppuccinFlavor}-${catppuccinAccent}-standard+rimless,black";
    # Force apps to find schemas
    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
  };

  # 3. GTK2/3 Configuration
  gtk = lib.mkIf catppuccin {
    enable = true;
    theme = {
      package = lib.mkForce (
        pkgs.catppuccin-gtk.override {
          accents = [ catppuccinAccent ];
          size = "standard";
          tweaks = [ "rimless" "black" ];
          variant = catppuccinFlavor;
        }
      );
      name = lib.mkForce "catppuccin-${catppuccinFlavor}-${catppuccinAccent}-standard+rimless,black";
    };

    # Force Dark/Light mode preference in GTK configs
    gtk3.extraConfig.gtk-application-prefer-dark-theme = if polarity == "dark" then 1 else 0;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = if polarity == "dark" then 1 else 0;
  };
}
```

# ~nixOS/home-manager/modules/zsh.nix

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



---

## The Code
This code is my personal one, but it may be change heavily based on your preferences

```nix
{
  config,
  pkgs,
  nixImpure,
  hostname,
  ...
}:
{
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

        switchCmd =
          if nixImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

        updateCmd =
          if nixImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        updateBoot =
          if nixImpure then
            "sudo nixos-rebuild boot --flake . --impure"
          else
            "nh os boot --update ${flakeDir}";
      in
      {

        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        upd = "cd ${flakeDir} && ${updateCmd}";

        # Manual are kept for reference, but use the above aliases instead
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # System maintenance
        dedup = "nix store optimise";
        cleanup = "nh clean all";

        # Home-Manager related
        hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#$(hostname)"; # Rebuild home-manager config

        # Pkgs editing
        pkgs-home = "nvim ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "nvim ${flakeDir}/hosts/${hostname}/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch

        # Utilities
        npu = "read 'url?Enter URL: ' && nix-prefetch-url \"$url\"";
        se = "sudoedit";

        # Various
        reb-uefi = "systemctl reboot - -firmware-setup"; # Reboot into UEFI firmware settings
        swboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    # -----------------------------------------------------
    # ⚙️ SHELL INITIALIZATION
    # -----------------------------------------------------
    initExtra = ''
      # 1. FIX HYPRLAND SOCKET (Dynamic Update)
      # This ensures that even inside tmux or after a crash, the shell finds the correct socket.
      if [ -d "/run/user/$(id -u)/hypr" ]; then
        export HYPRLAND_INSTANCE_SIGNATURE=$(ls -w 1 /run/user/$(id -u)/hypr/ | grep -v ".lock" | head -n 1)
      fi

      # 2. LOAD USER CONFIG (Stow Integration)
      if [ -f "$HOME/.zshrc_custom" ]; then
        source "$HOME/.zshrc_custom"
      fi

      # 3. TMUX AUTOSTART (Only in GUI)
      # Ensure we are in a GUI before starting tmux automatically
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux new-session
      fi

      # 4. UWSM STARTUP (Universal & Safe)
      # Guard: Only run if on physical TTY1 AND no graphical session is active.
      if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
          
          # Check if uwsm is installed and ready (Safe for KDE/GNOME-only builds)
          if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
              exec systemd-cat -t uwsm_start uwsm start default
          fi
      fi
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

{
  imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./local-packages.nix

    # Flatpak support
    ./flatpak.nix

    # Core imports
    ../../nixos/modules/core.nix
  ];

  hardware.graphics.enable = true; # Keep enabled to avoid terminal crash when disabling certain de

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  fonts.fontconfig.enable = true;

  environment.systemPackages = with pkgs; [
    iptables
    glib
    gsettings-desktop-schemas
    gtk3
    libsForQt5.qt5.qtwayland # Qt5 Wayland platform plugin
    kdePackages.qtwayland # Qt6 Wayland platform plugin
  ];

  programs.dconf.enable = true;

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY
  # ---------------------------------------------------------
  # Dynamically sets the hostname passed from flake.nix
  networking.hostName = hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # ---------------------------------------------------------
  # ⚔️ STABILITY FIX: Force 'Switch User' to act as 'Log Out'
  # ---------------------------------------------------------
  # This was done mainly to help the guest user to be kicked out from unauthorized sessions
  systemd.tmpfiles.rules = [
    "f /etc/systemd/logind.conf.d/10-logout-override.conf 0644 root root - [Login]\nKillUserProcesses=yes\nIdleAction=none\n"
  ];

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
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh; # Ensure zsh is installed in system packages
  };

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
  term,
  editor,
  browser,
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
    "nvim" = "nvim";
    "vim" = "vim";
  };

  # Select the correct command, or default to the name itself if unknown
  finalEditor = editorFlags.${editor} or editor;
in
{
  environment.sessionVariables = {
    BROWSER = browser;

    TERMINAL = term;

    EDITOR = finalEditor;

    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [
      "$HOME/.local/bin"
    ];
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
* **Anti-Lockout:** We modify XFCE's kiosk settings (`kioskrc`) to disable "Switch User". This forces a full logout, ensuring the guest session (and its data) is cleared before you log back in.

### 4. User Warning

A custom script (`guest-warning`) runs on login using `zenity`. It displays a bilingual (English/Italian) popup warning the user that "This is a temporary session" and that all files will be deleted upon restart.

---

## The Code

```nix
{
  config,
  pkgs,
  lib,
  guest,
  ...
}:

let
  guestUid = 2000;

  # 1. WARNING SCRIPT
  # A simple shell script that creates a GUI popup using Zenity.
  guestWarningScript = pkgs.writeShellScriptBin "guest-warning" ''
    # Safety checks: Only run for the guest user in the XFCE environment
    if [ "$USER" != "guest" ]; then exit 0; fi
    if [[ "$XDG_CURRENT_DESKTOP" != *"XFCE"* ]]; then exit 0; fi

    sleep 3
    
    # Display the warning dialog
    ${pkgs.zenity}/bin/zenity --warning \
      --title="Guest Mode / Modalità ospite" \
      --text="<span size='large' weight='bold'>⚠️  Warning: Temporary Session</span>\n\nThis is a guest session.\nAll files, downloads, and settings will be \n<span color='red'>PERMANENTLY DELETED</span> when you restart the computer.\n\n──────────────────────────────\n\n<span size='large' weight='bold'>⚠️  Attenzione: Sessione temporanea</span>\n\nQuesta è una sessione ospite.\nTutti i file, download e impostazioni VERRANNNO <span color='red'>CANCELLATI PERMANENTEMENTE</span> al riavvio del computer." \
      --width=500
  '';
in
{
  # Only enable this configuration if 'guest = true' in variables.nix
  config = lib.mkIf guest {

    # ---------------------------------------------------------
    # 👤 USER ACCOUNT
    # ---------------------------------------------------------
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
      # Pre-hashed password (usually simple, e.g., "guest" or empty)
      hashedPassword = "$6$Cqklpmh3CX0Cix4Y$OCx6/ud5bn72K.qQ3aSjlYWX6Yqh9XwrQHSR1GnaPRud6W4KcyU9c3eh6Oqn7bjW3O60oEYti894sqVUE1e1O0";
      createHome = true;
      shell = pkgs.bash;
    };

    users.groups.guest = {
      gid = guestUid;
    };

    # ---------------------------------------------------------
    # 🛡️ SECURITY & SESSION RULES
    # ---------------------------------------------------------
    
    # 🚫 DISABLE "SWITCH USER"
    # Prevents leaving the guest session active in the background.
    # Forces the user to Log Out, which is cleaner for a temporary session.
    environment.etc."xdg/xfce4/kiosk/kioskrc".text = ''
      [xfce4-session]
      SwitchUser=root
      SaveSession=NONE
    '';

    # 🧹 EPHEMERAL HOME (RAM DISK)
    # Mounts /home/guest as a tmpfs.
    # Data is stored in RAM and vanishes on power loss/reboot.
    fileSystems."/home/guest" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "size=25%" # Limit to 25% of total system RAM
        "mode=700" # Only guest can read/write
        "uid=${toString guestUid}"
        "gid=${toString guestUid}"
      ];
    };

    # ---------------------------------------------------------
    # 🖥️ DESKTOP ENVIRONMENT (XFCE)
    # ---------------------------------------------------------
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    # 🎯 FORCE XFCE DEFAULT
    # Uses AccountsService to tell the Display Manager:
    # "When user 'guest' logs in, ALWAYS use the 'xfce' session."
    systemd.tmpfiles.rules = [
      "d /var/lib/AccountsService/users 0755 root root -"
      "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
    ];

    # 📦 GUEST PACKAGES
    # A minimal set of tools for a guest user.
    environment.systemPackages = with pkgs;
    [
      (google-chrome.override {
        # Ensure Chrome starts fresh every time
        commandLineArgs = "--no-first-run --no-default-browser-check";
      })
      nemo          # File Manager
      eog           # Image Viewer
      file-roller   # Archive Manager
      gnome-calculator
      zenity        # Required for the warning script
    ];

    # ⚠️ AUTOSTART WARNING
    # Creates an XDG autostart entry to launch the warning script on login.
    environment.etc."xdg/autostart/guest-warning.desktop".text = ''
      [Desktop Entry]
      Name=Guest Warning
      Exec=${guestWarningScript}/bin/guest-warning
      Type=Application
      Terminal=false
      OnlyShowIn=XFCE;
    '';

    # ---------------------------------------------------------
    # 🚧 NETWORK & HARDWARE RESTRICTIONS
    # ---------------------------------------------------------

    # 🛡️ FIREWALL (Tailscale Isolation)
    # Prevents the guest from accessing your private VPN network.
    networking.firewall.extraCommands = lib.mkIf config.services.tailscale.enable ''
      iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -o tailscale0 -j REJECT
      iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -d 100.64.0.0/10 -j REJECT
    '';

    # 🔒 POLKIT RULES
    # 1. Prevent mounting internal system drives (udisks2)
    # 2. Prevent suspending or hibernating the machine
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "guest") {
          if (action.id.indexOf("org.freedesktop.udisks2.filesystem-mount-system") == 0) {
            return polkit.Result.NO;
          }
          if (action.id.indexOf("org.freedesktop.login1.suspend") == 0 ||
              action.id.indexOf("org.freedesktop.login1.hibernate") == 0) {
            return polkit.Result.NO;
          }
        }
      });
    '';

    # ⚖️ RESOURCE LIMITS
    # Prevents the guest from crashing the system by using too much RAM/CPU.
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
This code is my personal one, but it may be change heavily based on your preferences

```nix
{
  pkgs,
  browser,
  editor,
  fileManager,
  ...
}:
let
  mkDesktop =
    name:
    if name == "dolphin" then
      "org.kde.dolphin.desktop"
    else if name == "kate" then
      "org.kde.kate.desktop"
    else if name == "vscode" || name == "code" then
      "code.desktop"
    else
      "${name}.desktop";

  myBrowser = mkDesktop browser;
  myFileManager = mkDesktop fileManager;
  myEditor = mkDesktop editor;
in
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = myFileManager;

      "text/html" = myBrowser;
      "x-scheme-handler/http" = myBrowser;
      "x-scheme-handler/https" = myBrowser;
      "x-scheme-handler/about" = myBrowser;
      "x-scheme-handler/unknown" = myBrowser;

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
      "application/pdf" = "org.pwmt.zathura.desktop";
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
{
  pkgs,
  lib,
  user,
  hyprland,
  ...
}:
let
  # Define the custom theme package
  sddmTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "jake_the_dog";
  };
in
{
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    
    # 🛑 STABILITY
    # We force SDDM to run on X11 because it is currently more stable 
    # and theme-compatible than the Wayland mode.
    wayland.enable = false;

    # Use the KDE 6 (Qt6) version of SDDM
    package = lib.mkForce pkgs.kdePackages.sddm;
    
    theme = "sddm-astronaut-theme";

    # 📦 DEPENDENCIES
    # Required for the theme to render SVGs and play animations
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };

  # Install the theme and cursor globally so SDDM can find them
  environment.systemPackages = [
    sddmTheme
    pkgs.bibata-cursors
  ];

  services.displayManager.autoLogin = {
    enable = false; # Require password on boot
    user = user;
  };

  # 🚀 DEFAULT SESSION
  # If Hyprland is active, default to the UWSM-wrapped session
  services.displayManager.defaultSession = lib.mkIf hyprland "hyprland-uwsm";

  # Disable TTY autologin to ensure security
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

We explicitly set **Zsh** as the default shell for the user account here. This ensures that even if you create a new user or move to a new host, you invariably get the advanced shell features (autosuggestions, syntax highlighting) defined in `modules/zsh.nix` without needing to configure it manually every time.

---

## The Code

```nix
{ pkgs, user, ... }:
{
  programs.zsh.enable = true; # Enable Zsh as a shell

  users = {
    defaultUserShell = pkgs.zsh; # Sets Zsh as the default shell globally

    users.${user} = {
      isNormalUser = true; # Marks this account as a regular human user

      # 🛡️ BASE PERMISSIONS (Safety Net)
      # These ensure that no matter what happens in the host config,
      # the user can always administer the system and connect to the internet.
      extraGroups = [
        "wheel"           # Sudo access
        "networkmanager"  # Wi-Fi/Ethernet control
      ];
    };
  };
}
```

