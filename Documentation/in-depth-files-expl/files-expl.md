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
    - [4. Conditionals](#4-conditionals)
  - [The Code](#the-code-7)
- [~nixOS/home-manager/modules/wofi/default.nix](#nixoshome-managermoduleswofidefaultnix)
  - [Key Concepts](#key-concepts-7)
    - [1. Manual Palette Definition](#1-manual-palette-definition)
    - [2. Hybrid Theming Strategy (Semantic Mapping)](#2-hybrid-theming-strategy-semantic-mapping)
    - [3. CSS Injection](#3-css-injection)
  - [The Code](#the-code-8)
- [~nixOS/home-manager/modules/qt.nix](#nixoshome-managermodulesqtnix)
  - [Key Concepts](#key-concepts-8)
    - [1. The "Magic" Fix: `QT_QPA_PLATFORMTHEME=kde`](#1-the-magic-fix-qt_qpa_platformthemekde)
    - [2. "Faking" the KDE Environment (`kdeglobals`)](#2-faking-the-kde-environment-kdeglobals)
    - [3. Dual Configuration (`qt5ct` as Backup)](#3-dual-configuration-qt5ct-as-backup)
  - [The Code](#the-code-9)
- [~nixOS/home-manager/modules/stylix.nix](#nixoshome-managermodulesstylixnix)
  - [Key Concepts](#key-concepts-9)
    - [1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)](#1-the-traffic-cop-strategy-catppuccin-vs-base16)
    - [2. The Qt/KDE Cohesion Strategy (Manual Hand-off)](#2-the-qtkde-cohesion-strategy-manual-hand-off)
      - [How the Cohesion Works:](#how-the-cohesion-works)
    - [3. Global Assets](#3-global-assets)
  - [The Code](#the-code-10)
- [~nixOS/home-manager/modules/zsh.nix](#nixoshome-managermoduleszshnix)
  - [Key Concepts](#key-concepts-10)
    - [1. Smart Rebuild Aliases (Impure vs. Pure)](#1-smart-rebuild-aliases-impure-vs-pure)
    - [2. Hybrid Configuration (`.zshrc_custom`)](#2-hybrid-configuration-zshrc_custom)
    - [3. The Startup Sequence](#3-the-startup-sequence)
  - [The Code](#the-code-11)
- [~nixOS/nixos/modules/common-configuration.nix](#nixosnixosmodulescommon-configurationnix)
  - [Key Concepts](#key-concepts-11)
    - [1. The "Survival Kit" (Universal Packages)](#1-the-survival-kit-universal-packages)
    - [2. Architecture Intelligence (x86 vs. ARM)](#2-architecture-intelligence-x86-vs-arm)
    - [3. Performance \& Responsiveness](#3-performance--responsiveness)
    - [4. Security Baseline](#4-security-baseline)
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
- [~nixOS/home-manager/modules/mime.nix](#nixoshome-managermodulesmimenix)
  - [Key Concepts](#key-concepts-15)
    - [1. Dynamic Associations](#1-dynamic-associations)
    - [2. Desktop File Translation (`mkDesktop`)](#2-desktop-file-translation-mkdesktop)
  - [The Code](#the-code-16)
- [~nixOS/nixos/modules/nix.nix](#nixosnixosmodulesnixnix)
  - [Key Concepts](#key-concepts-16)
    - [1. Enabling Flakes](#1-enabling-flakes)
    - [2. Binary Caching (Speed)](#2-binary-caching-speed)
    - [3. Automatic Garbage Collection](#3-automatic-garbage-collection)
  - [The Code](#the-code-17)
- [~nixOS/nixos/modules/sddm.nix](#nixosnixosmodulessddmnix)
  - [Key Concepts](#key-concepts-17)
    - [1. The "Astronaut" Theme](#1-the-astronaut-theme)
  - [The Code](#the-code-18)
- [~nixOS/nixos/modules/user.nix](#nixosnixosmodulesusernix)
  - [Key Concepts](#key-concepts-18)
    - [1. The "Safety Net" (Why configure groups twice?)](#1-the-safety-net-why-configure-groups-twice)
    - [2. Global Shell Enforcement](#2-global-shell-enforcement)
  - [The Code](#the-code-19)


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

    # Needed to get firefox addons from nur
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official catppuccin-nix flake
    catppuccin = {
      url = "github:catppuccin/nix";
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
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      hostNames = nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs (
          name: type:
          type == "directory" && builtins.pathExists (./hosts + "/${name}/hardware-configuration.nix")
        ) (builtins.readDir ./hosts)
      );

      # 🛠️ SYSTEM BUILDER
      makeSystem =
        hostname:
        let
          # 1. Base Vars (Always exist)
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import host-specific optional folder
          hostPath = ./hosts/${hostname};
          optionalPath = hostPath + "/optional";

          # 3. Load Home-Manager variables (modules.nix)
          modulesPath = optionalPath + "/general-hm-modules/modules.nix";

          # 4. Extra Vars (Optional - host specific HM settings)
          extraVars =
            if builtins.pathExists modulesPath then
              builtins.trace "✅ [${hostname} System] Loading host HM Variables from: ${toString modulesPath}" (
                import modulesPath {
                  vars = baseVars;
                  lib = nixpkgs.lib;
                  pkgs = nixpkgs.pkgs;
                }
              )
            else
              builtins.trace
                "ℹ️ [${hostname} System] No host HM Variables module found at ${toString modulesPath}"
                { };

          # 5. Merge: Base + Extra + Hostname
          hostVars = baseVars // extraVars // { inherit hostname; };

          # 6. Check for host home file
          hostHomeFile = ./hosts/${hostname}/home.nix;
          hostHomeExists = builtins.pathExists hostHomeFile;

          # 7. Unstable pkgs
          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {

          specialArgs = {
            inherit inputs pkgs-unstable;
            vars = hostVars;
          };

          modules = [
            # Base NixOS modules
            ./nixos/modules/core.nix
            ./hosts/${hostname}/configuration.nix
            ./hosts/${hostname}/hardware-configuration.nix

            # Overlay needed to avoid problems for aarch64
            (
              { pkgs, lib, ... }:
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    gpu-screen-recorder =
                      if prev.stdenv.hostPlatform.system == "aarch64-linux" then
                        prev.writeShellScriptBin "gpu-screen-recorder" ''
                          echo "GPU Screen Recorder is not supported on ARM"
                          exit 0
                        ''
                      else
                        prev.gpu-screen-recorder;
                  })
                ];
              }
            )

            # Additional nixos modules from flakes
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.nix-sops.nixosModules.sops
            inputs.niri.nixosModules.niri

            # Import entire optional host-specific directory if it exists
            (
              if builtins.pathExists optionalPath then
                builtins.trace "✅ [${hostname} System] Importing Host Optional Dir: ${toString optionalPath}" optionalPath
              else
                builtins.trace "ℹ️ [${hostname} System] No Optional Dir found." { }
            )

            {
              # host-specific variables
              nixpkgs.hostPlatform = hostVars.system;
            }
            # Home-Manager
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # Home-manager flakes input integration
              home-manager.sharedModules = [
                inputs.catppuccin.homeModules.catppuccin
                inputs.plasma-manager.homeModules.plasma-manager
              ];

              # Home-manager unstable import (needed)
              home-manager.extraSpecialArgs = {
                inherit inputs pkgs-unstable hostname;
                vars = hostVars;
              };

              # Home-manager host-specific user configuration
              home-manager.users.${hostVars.user} = {
                imports = [
                  ./home-manager/home.nix
                ]
                ++ (
                  if hostHomeExists then
                    builtins.trace "✅ [${hostname} System] Importing Host Home: ${toString hostHomeFile}" [
                      hostHomeFile
                    ]
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
          # 1. Base Vars (Always exist)
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import host-specific optional folder
          hostPath = ./hosts/${hostname};
          optionalPath = hostPath + "/optional";

          # 3. Load Home-Manager variables (modules.nix)
          modulesPath = optionalPath + "/general-hm-modules/modules.nix";

          # 4. Extra Vars (Optional - host specific HM settings)
          extraVars =
            if builtins.pathExists modulesPath then
              builtins.trace "✅ [${hostname} Home] Loading host HM Variables from: ${toString modulesPath}" (
                import modulesPath {
                  vars = baseVars;
                  lib = nixpkgs.lib;
                  pkgs = nixpkgs.pkgs;
                }
              )
            else
              builtins.trace "ℹ️ [${hostname} Home] No hsot HM Variables module found." { };

          # 5. Merge: Base + Extra + Hostname
          hostVars = baseVars // extraVars // { inherit hostname; };

          # 6. Check for host home file
          hostHomeFile = ./hosts/${hostname}/home.nix;

          # Create a list of extra modules to append
          extraModules = nixpkgs.lib.optional (builtins.pathExists hostHomeFile) (
            builtins.trace "✅ [${hostname} Home] Adding Host Home: ${toString hostHomeFile}" hostHomeFile
          );

          # 7. Unstable pkgs
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
          ++ extraModules;
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
    # If a package does not need/can't be configured with home-manager then it can be in common-configuration.nix or a host-specific configuration.nix
    ++ (with pkgs; [

      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      cliphist # Wayland clipboard history manager (needed for clipboard management in most de/wm modules)

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
    ])

    # 3. KDE PACKAGES
    ++ (with pkgs.kdePackages; [
      gwenview # Default image viewer as defined in mime.nix
    ])

    # 4. UNSTABLE PACKAGES
    ++ (with pkgs-unstable; [ ]);
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
  inputs,
  pkgs,
  vars,
  ...
}:
let
  noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  caelestiaPkg = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;
in
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

        # -----------------------------------------------------
        # 🌍 Environment Variables
        # -----------------------------------------------------
        # These ensure apps (Electron, QT, etc.) know they are running on Wayland.
        env =
          let
            firstMonitor = builtins.elemAt vars.monitors 0;
            monitorParts = lib.splitString "," firstMonitor;
            rawScale = if (builtins.length monitorParts) >= 4 then builtins.elemAt monitorParts 3 else "1";
            gdkScale = if rawScale != "1" && rawScale != "1.0" then "2" else "1";
          in
          [
            # Communicate with apps to tell them we are on Wayland
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

            # THEMING & AESTHETICS
            "QT_QPA_PLATFORMTHEME,kde" # Tells Qt apps to use the 'kde' engine if available (enables breeze theme).

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
        "$Mod" = "SUPER";
        "$term" = vars.term;

        # Distinguish between terminal-based and GUI file managers
        "$fileManager" = "${
          if vars.fileManager == "yazi" || vars.fileManager == "ranger" then
            "${vars.term} --class ${vars.fileManager} -e ${vars.fileManager}"
          else
            "${vars.fileManager}"
        }";

        # Distinguish between terminal-based and GUI editors
        "$editor" = "${
          if vars.editor == "nvim" then "${vars.term} --class nvim-editor -e nvim" else "${vars.editor}"
        }";

        # Dynamic menu command based on launcher choice
        "$menu" = "${
          if (vars.hyprlandCaelestia or false) then
            # 🟢 FIXED: Use the wrapper + the correct 'drawers' command
            "caelestiaqs ipc call drawers toggle launcher"
          else if (vars.hyprlandNoctalia or false) then
            "sh -c '${noctaliaPkg}/bin/noctalia-shell ipc call launcher toggle'"
          else
            "wofi --show drun"
        }";

        # -----------------------------------------------------
        # 🚀 Startup Apps
        # ----------------------------------------------------
        exec-once = [
          "wl-paste --type text --watch cliphist store" # Start clipboard manager for text
          "wl-paste --type image --watch cliphist store" # Start clipboard manager for images
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # Keep for snapper polkit support
          "pkill ibus-daemon" # Kill ibus given by gnome
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" # Keeps dbus environment updated for Wayland apps.
        ]
        ++ (vars.hyprland_Exec-Once or [ ]);

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


### 4. Conditionals
The waybar is enabled/disabled depending on if `noctalia/caelestia` are used and it adapt to the workspace differences between `niri` and `hyprland`

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
  # 1. Hyprland logic: Show Waybar if no custom shell is set
  hyprlandWaybar =
    (vars.hyprland or false)
    && !((vars.hyprlandCaelestia or false) || (vars.hyprlandNoctalia or false));

  # 2. Niri logic: Show Waybar if no custom shell is set
  niriWaybar = (vars.niri or false) && !(vars.niriNoctalia or false);
in
{
  config = lib.mkIf (hyprlandWaybar || niriWaybar) {

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
          # A user may define host-specific icons (optional) in vars.waybarWorkspaceIcons
          "hyprland/workspaces" = {
            disable-scroll = true;
            show-special = true;
            special-visible-only = true;
            all-outputs = false;
            format = "{name} {icon}";
            format-icons = vars.waybarWorkspaceIcons or { };
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
          # A user may define host-specific layout text (optional) in vars.waybarLayout
          "hyprland/language" = {
            min-length = 5;
            tooltip = true;
            on-click = "hyprctl switchxkblayout all next";
          }
          // vars.waybarLayout or { };

          "niri/language" = {
            format = "{}";
            # This command cycles to the next configured layout in Niri
            on-click = "niri msg action switch-layout-next";
          }

          // vars.waybarLayout or { };
          # Weather module with wttr.in
          # It fetches the location from variables.nix and when clicked the favorite browser opens wttr.in page
          "custom/weather" = {
            format = "<span color='${c.base0C}'>${vars.weather}:</span> {} ";
            exec =
              let
                unit = if (vars.useFahrenheit or false) then "°C" else "°F";
              in
              "curl -s 'wttr.in/${vars.weather}?format=%c%t&${unit}' | sed 's/ //'";
            interval = 300;
            class = "weather";
            on-click = ''xdg-open "https://wttr.in/${vars.weather}"'';
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

          # General app tray settings
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
---

# ~nixOS/home-manager/modules/qt.nix

This file manages the look and feel of **Qt applications** (like Dolphin, VLC, OBS, KeepassXC).

It aims for a **native KDE Plasma look** (using the **Breeze** style) even when running on Hyprland.

---

## Key Concepts

### 1. The "Magic" Fix: `QT_QPA_PLATFORMTHEME=kde`

In your `hyprland-main.nix`, you set the environment variable `QT_QPA_PLATFORMTHEME=kde`. This is the single most important setting for Qt apps on Hyprland.

* **(`kde`):** By setting the platform to `kde`, we tell Qt apps: *"Act as if you are running inside a full KDE Plasma session."*

**Why it fixes the problem:** When Qt thinks it is in KDE, it loads the `plasma-integration` plugin (which you install in this file ). This plugin is much smarter than `qt5ct`. It automatically handles:


* Correct file dialogs (using the portal).
* Icon theme association.
* System color schemes.
* **Crucially:** It allows the **Breeze style** to render 100% correctly, looking exactly as it would on a Plasma desktop.



### 2. "Faking" the KDE Environment (`kdeglobals`)

Since you are running Hyprland, you don't actually have the KDE settings daemon running. For the `kde` platform theme to work, it needs to find the configuration files it *expects* to see in a real Plasma session.

**The Activation Script:** This module includes a `home.activation` script. It runs every time you rebuild your system.


* **What it does:** It uses `kwriteconfig6` to manually write a standard KDE configuration file (`~/.config/kdeglobals`).
* **The Result:** It injects your chosen color scheme (`BreezeDark` or `BreezeLight`) and icon theme (`Papirus`) directly into this file. When a Qt app launches, it reads this "fake" file and applies your colors perfectly.

### 3. Dual Configuration (`qt5ct` as Backup)

Although the `kde` platform theme is the priority, this file still generates configuration files for `qt5ct` and `qt6ct`.

* **Consistency:** It ensures that even if an app ignores the `kde` platform override and falls back to generic settings, it is still forced to use the `breeze` style and your specified color scheme paths.

**Color Linking:** It links the official KDE Breeze color files from the nix store into `~/.local/share/color-schemes` so both the KDE integration and generic Qt tools can find them.



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
  hyprEnabled = vars.hyprland or false;
  kdeEnabled = vars.kde or false;
  useKdePlatformTheme = hyprEnabled || kdeEnabled;
  isDark = (vars.polarity or "dark") == "dark";
  kdeColorScheme = if isDark then "BreezeDark" else "BreezeLight";
  iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";
in
{
  home.packages =
    (with pkgs; [
      libsForQt5.qt5ct
      kdePackages.qt6ct

      papirus-icon-theme
    ])
    ++ (with pkgs; [ kdePackages.breeze ])
    ++ lib.optionals useKdePlatformTheme (
      with pkgs;
      [
        kdePackages.plasma-integration

        kdePackages.kconfig
        libsForQt5.kconfig
      ]
    );

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

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt6ct/colors/${kdeColorScheme}.colors
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt5ct/colors/${kdeColorScheme}.colors
  '';

  home.activation.kdeglobalsFromPolarity = lib.mkIf useKdePlatformTheme (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons      --key Theme      "${iconThemeName}"  || true

      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group Icons      --key Theme      "${iconThemeName}"  || true
    ''
  );
}
```

---

# ~nixOS/home-manager/modules/stylix.nix

This file configures **Stylix**, the central theming engine for the system. Stylix's job is to take a single "Base16" color scheme (or an image) and automatically inject it into *every* application on your system (Shell, Editor, Browser, Desktop).

However, because we also support the official **Catppuccin** modules and require stable Qt behavior, this file acts as a **"Traffic Cop"**. It intelligently decides *who* gets to theme *what*.


## Key Concepts

### 1. The "Traffic Cop" Strategy (Catppuccin vs. Base16)

We want the best of both worlds:

* **If Catppuccin is Enabled:** We want the official Catppuccin modules (which are hand-tuned and often look better than generic generated themes) to handle applications like Hyprland, Alacritty, and Bat.
* **If Catppuccin is Disabled:** We want Stylix to automatically generate a theme for *everything* based on the `base16Theme` variable (e.g., Dracula, Gruvbox, Nord).

We achieve this using the `!catppuccin` logic.

* `hyprland.enable = !catppuccin;` → "Only let Stylix theme Hyprland if Catppuccin is false."

### 2. The Qt/KDE Cohesion Strategy (Manual Hand-off)

You will notice that **`kde.enable`** and **`qt.enable`** are explicitly set to **`false`**. This is a deliberate "Separation of Powers" between `stylix.nix` and `qt.nix`.

* **The Problem:** Stylix attempts to force generic Base16 colors onto Qt applications (using `qt5ct`). On KDE Plasma, this conflicts with the desktop's native engine, often causing login loops or crashes. On Hyprland, it often results in broken icons or unreadable text.
* **The Solution (The Hand-off):** We tell Stylix to ignore Qt entirely. Instead, we delegate Qt theming to our custom **`modules/qt.nix`**.

#### How the Cohesion Works:

Even though they are separate files, they stay synchronized via the global **`vars.polarity`** variable:

1. **Stylix (GTK & Others):** Reads `vars.polarity` (Dark/Light) and generates the appropriate GTK theme and wallpaper.
2. **`qt.nix` (Qt & KDE):** Reads the same `vars.polarity` variable.
* If `dark`: It forces the native **Breeze Dark** theme and **Papirus-Dark** icons.
* If `light`: It forces **Breeze Light** and **Papirus-Light**.


3. **Result:** Your GTK apps (themed by Stylix) and Qt apps (handled by `qt.nix`) always share the same Dark/Light mode, ensuring a consistent system look without the instability of forcing Stylix upon Qt.

### 3. Global Assets

Regardless of which theme engine we use for specific apps, Stylix always manages the **universal** assets to ensure consistency:

* **Wallpaper:** Sets the background image for the system.
* **Fonts:** Enforces `JetBrainsMono Nerd Font` everywhere.
* **Cursor:** Enforces the `DMZ-Black` cursor.

---

## The Code

```nix
{
  pkgs,
  lib,
  inputs,
  vars,
  ...
}:
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

      # These should remain enabled to avoid conflicts with other modules

      # -----------------------------------------------------------------------
      # DE/WM SPECIFIC
      # -----------------------------------------------------------------------
      gnome.enable = vars.gnome;

      # ---------------------------------------------------------------------------------------
      # 🎨 GLOBAL CATPPUCCIN
      # Intelligently enable/disable stylix based on whether catppuccin is enabled
      # catppuccin = true -> .enable = false
      # catppuccin = false -> .enable = true
      hyprland.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/main.nix

      hyprlock.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/hyprlock.nix

      gtk.enable = !vars.catppuccin; # No ref

      swaync.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/swaync/default.nix

      bat.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/bat.nix

      lazygit.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/lazygit.nix

      tmux.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/tmux.nix

      starship.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/starship.nix

    }
    // (lib.optionalAttrs (vars.stylixExclusions != null) vars.stylixExclusions);

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
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = if vars.polarity == "dark" then "prefer-dark" else "prefer-light";
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

# ~nixOS/nixos/modules/common-configuration.nix

This file serves as the **universal baseline** for every machine in your infrastructure (desktops, laptops, etc.). It ensures that regardless of the specific hardware, every host starts with the same core tools, security policies, and performance tweaks.

---

## Key Concepts

### 1. The "Survival Kit" (Universal Packages)

It installs packages needed for every host to make this os work


### 2. Architecture Intelligence (x86 vs. ARM)

The file is smart enough to adapt based on the CPU architecture, preventing build errors on incompatible hardware.


**x86_64 Only:** It installs `gpu-screen-recorder` and sets up its root security wrappers *only* if the system is an Intel/AMD machine.



**ARM (Laptops):** It silently skips these packages, ensuring your MacBook or ARM laptop builds successfully without trying to compile incompatible software.



### 3. Performance & Responsiveness

It applies global tweaks to make the system feel snappier:

* 
**System76 Scheduler:** Prioritizes the app you are currently using (foreground) for smoother performance.


* 
**Fast Boot:** Disables the "wait for network" service, which significantly speeds up startup times.


* 
**Power Management:** Enables modern daemons (`upower`, `power-profiles-daemon`) needed for battery reporting and UI integrations.



### 4. Security Baseline

It establishes the default security posture for the OS:

* 
**Polkit Rules:** Automatically approves specific safe actions (like realtime audio processing) for admin users to reduce annoying password prompts.


* 
**Privilege Wrappers:** Sets up security wrappers (like `cap_sys_admin` for screen recording) needed for specific tools to function without compromising the whole system.

---

## The Code

```nix
{
  config,
  pkgs,
  lib,
  vars,
  ...
}:
let
  shellPkg =
    if vars.shell == "fish" then
      pkgs.fish
    else if vars.shell == "zsh" then
      pkgs.zsh
    else
      pkgs.bashInteractive;
in
{

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY
  # ---------------------------------------------------------
  networking.hostName = vars.hostname;
  networking.networkmanager.enable = true;
  system.stateVersion = vars.stateVersion;

  # ---------------------------------------------------------
  # 🌍 LOCALE & TIME
  # ---------------------------------------------------------
  time.timeZone = vars.timeZone;

  # Keyboard Layout
  services.xserver.xkb = {
    layout = vars.keyboardLayout;
    variant = vars.keyboardVariant;
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
  };

  # Allow unfree packages globally (needed for drivers, code, etc.)
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------
  # 📦 SYSTEM PACKAGES
  # ---------------------------------------------------------
  environment.systemPackages =
    with pkgs;
    [
      # --- CLI UTILITIES ---
      eza # Global home-manager module
      fzf # Used by the shells
      git # Version control
      nixfmt-rfc-style # Nix formatter
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used in zsh.nix module)
      starship # Global home-manager module
      curl # Used by waybar

      # --- SYSTEM TOOLS ---
      foot # Tiny, zero-config terminal (Rescue tool)
      gsettings-desktop-schemas # Global theme settings
      libnotify # Library for desktop notifications (used by most de/wm modules)
      polkit_gnome # Authentication agent
      sops # Secret management
      shellPkg # The selected shell package (bash, zsh, or fish)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers

      # --- GRAPHICS & GUI SUPPORT ---
      gtk3 # Standard GUI toolkit
      libsForQt5.qt5.qtwayland # Qt5 Wayland bridge
      kdePackages.qtwayland # Qt6 Wayland bridge
      powerline-symbols # Terminal font glyphs
    ]
    # Installation of packages available only on x86_64 systems
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      builtins.trace "✅ x86_64 Architecture Detected: Installing x86 only packages" [
        gpu-screen-recorder
      ]
    )

    # Extra KDE specific packages
    ++ (with pkgs.kdePackages; [
      gwenview # Default image viewer as defined in mime.nix
      kio-extras # Extra protocols for KDE file dialogs (needed for dolphin remote access)
      kio-fuse # Mount remote filesystems (via ssh, ftp, etc.) in Dolphin
    ])

    # Extra packages from unstable channel
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
  ];
  fonts.fontconfig.enable = true;

  # ---------------------------------------------------------
  # 🛡️ SECURITY & WRAPPERS
  # ---------------------------------------------------------
  security.rtkit.enable = true;
  services.openssh.enable = true;

  # Only define these wrappers if we are on an x86 system.
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

  # Use optionalString to inject the GPU rule ONLY on x86.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        // Auto-approve realtime audio requests (Keep this for everyone)
        if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
            action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
          return polkit.Result.YES;
        }

        ${lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
          // Auto-approve gpu-screen-recorder running as root (x86 ONLY)
          if (action.id == "org.freedesktop.policykit.exec" &&
              action.lookup("program") &&
              action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
            return polkit.Result.YES;
          }
        ''}
      }
    });
  '';

  # ---------------------------------------------------------
  # 🐚 SHELLS & ENVIRONMENT
  # ---------------------------------------------------------
  programs.zsh.enable = vars.shell == "zsh";
  programs.fish.enable = vars.shell == "fish";

  # -----------------------------------------------------
  # 🎨 GLOBAL THEME VARIABLES
  # -----------------------------------------------------
  environment.variables.GTK_APPLICATION_PREFER_DARK_THEME =
    if vars.polarity == "dark" then "1" else "0";

  # -----------------------------------------------------
  # ⚡ SYSTEM TWEAKS
  # -----------------------------------------------------
  # Reduce shutdown wait time for stuck services
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };

  # Enable home-manager backup files
  home-manager.backupFileExtension = lib.mkForce "hm-backup";

  # Enable UPower for better power management and battery reporting (needed for noctalia shell)
  services.upower.enable = true;

  # Enable the modern power-profiles-daemon (needed for noctalia shell)
  services.power-profiles-daemon.enable = true;

  # Enable System76 Scheduler for improved desktop responsiveness
  services.system76-scheduler.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable = true; # Prioritizes foreground apps (smoothness)

  # Disable NetworkManager-wait-online to speed up boot time
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable emulation for aarch64 linux for testing purposes on x86_64 hosts
  boot.binfmt.emulatedSystems = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
    "aarch64-linux"
  ];

  # Add KWallet integration for SDDM and GDM display managers
  security.pam.services = {
    sddm.enableKwallet = config.services.displayManager.sddm.enable;
    gdm.enableKwallet = config.services.displayManager.gdm.enable;
  };

  # Explicitly disable TLP to avoid conflicts
  services.tlp.enable = false;
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
```nix
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

---

## The Code

```nix
{
  pkgs,
  lib,
  vars,
  ...
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
    wayland.enable = true;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";

    extraPackages = with pkgs; [
      kdePackages.qtsvg # Keep for the theme
      kdePackages.qtmultimedia # Keep for the theme
      #kdePackages.qtvirtualkeyboard
    ];
  };

  /*
    systemd.services.sddm.environment = {
      QT_IM_MODULE = "qtvirtualkeyboard";
      QT_VIRTUALKEYBOARD_DESKTOP_DISABLE = "0";
    };

    environment.etc."sddm.conf.d/virtual-keyboard.conf".text = ''
      [General]
      InputMethod=qtvirtualkeyboard
    '';
  */

  environment.systemPackages = [
    sddmTheme
    pkgs.bibata-cursors
  ];

  services.displayManager.autoLogin = {
    enable = false;
    user = vars.user;
  };

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

