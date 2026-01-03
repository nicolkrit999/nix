# ❄️ Personal NixOS Config
## Hyprland + waybar + lazygit + ranger + firefox
![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-showcase.png)

## Hyprland + caelestia/quickshell
![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-caelestia.png)

- [❄️ Personal NixOS Config](#️-personal-nixos-config)
  - [Hyprland + waybar + lazygit + ranger + firefox](#hyprland--waybar--lazygit--ranger--firefox)
  - [Hyprland + caelestia/quickshell](#hyprland--caelestiaquickshell)
  - [✨ Features](#-features)
    - [🖥️ Adaptive Host Support:](#️-adaptive-host-support)
    - [📦 Package version and flatpak](#-package-version-and-flatpak)
    - [❄️ Hybrid (declarative + non declarative for some modules)](#️-hybrid-declarative--non-declarative-for-some-modules)
    - [🎨 Theming](#-theming)
    - [🖌️ Wallpaper(s)](#️-wallpapers)
      - [kde-main.nix](#kde-mainnix)
      - [gnome-main.nix](#gnome-mainnix)
    - [🪟 Multiple Desktop Environments](#-multiple-desktop-environments)
      - [✅ The Safe Way (Prevent Lockouts)](#-the-safe-way-prevent-lockouts)
      - [🚨 Emergency Recovery (Stuck in TTY)](#-emergency-recovery-stuck-in-tty)
      - [🛠️ Troubleshooting](#️-troubleshooting)
    - [👤 Ephemeral Guest User](#-ephemeral-guest-user)
    - [🏠 Home Manager Integration](#-home-manager-integration)
    - [🧇 Tmux](#-tmux)
    - [🌟 Zsh + Starship](#-zsh--starship)
    - [🦺 BTRFS snapshots](#-btrfs-snapshots)
- [🚀 NixOS Installation Guide](#-nixos-installation-guide)
  - [📦 Phase 1: Preparation](#-phase-1-preparation)
    - [1. Download \& Flash](#1-download--flash)
    - [2. Boot \& Connect](#2-boot--connect)
  - [💾 Phase 2: The Terminal Installation](#-phase-2-the-terminal-installation)
    - [1. Download the Config](#1-download-the-config)
    - [2. Identify Your Disk](#2-identify-your-disk)
    - [3. Create Your Host](#3-create-your-host)
    - [4. Configure the Drive](#4-configure-the-drive)
    - [5. Configure Critical Variables](#5-configure-critical-variables)
    - [6. Install (The Magic Step)](#6-install-the-magic-step)
    - [7. Finish](#7-finish)
  - [🎨 Phase 3: Post-Install Setup](#-phase-3-post-install-setup)
    - [1. Move Config to Home](#1-move-config-to-home)
    - [2. (Optional) Cleanup Unused Hosts](#2-optional-cleanup-unused-hosts)
  - [🛠️ Phase 4: Customization](#️-phase-4-customization)
    - [Refine `variables.nix`](#refine-variablesnix)
      - [An hosts variable config example:](#an-hosts-variable-config-example)
    - [Setup `local-packages.nix`](#setup-local-packagesnix)
    - [Setup `flatpak.nix`](#setup-flatpaknix)
    - [Setup (optional) `modules.nix`](#setup-optional-modulesnix)
    - [Setup (optional) `home.nix`](#setup-optional-homenix)
    - [Setup (optional) `host-modules` folder](#setup-optional-host-modules-folder)
  - [Phase 5: Setup optional host-specific files and directories](#phase-5-setup-optional-host-specific-files-and-directories)
    - [1. (Optional) Customize the host-specific `modules.nix`](#1-optional-customize-the-host-specific-modulesnix)
      - [`modules.nix` Example](#modulesnix-example)
    - [2. (optional) Other files that may require manual attention](#2-optional-other-files-that-may-require-manual-attention)
      - [~/nixOS/home-manager/modules/firefox.nix and ~/nixOS/home-manager/modules/chromium.nix](#nixoshome-managermodulesfirefoxnix-and-nixoshome-managermoduleschromiumnix)
      - [~/nixOS/home-manager/modules/neovim.nix/](#nixoshome-managermodulesneovimnix)
      - [~/nixOS/home-manager/modules/zathura.nix/](#nixoshome-managermoduleszathuranix)
      - [~/nixOS/nixos/modules/mime.nix/](#nixosnixosmodulesmimenix)
    - [3. (Optional) Customize the host-specific `home.nix`](#3-optional-customize-the-host-specific-homenix)
      - [`home.nix` Example](#homenix-example)
    - [4. (Optional) Customize the host-specific `host-modules` directory](#4-optional-customize-the-host-specific-host-modules-directory)
  - [🔄 Daily Usage \& Updates](#-daily-usage--updates)
  - [❓ Troubleshooting](#-troubleshooting)
    - [Error: `path '.../hardware-configuration.nix' does not exist`](#error-path-hardware-configurationnix-does-not-exist)
    - [Error: `home-manager: command not found`](#error-home-manager-command-not-found)
    - [Error: `permission denied` opening `flake.lock`](#error-permission-denied-opening-flakelock)
    - [Error: `returned non-zero exit status 4` during rebuild](#error-returned-non-zero-exit-status-4-during-rebuild)
    - [Error: `evaluation warning: `programs.zsh.initExtra`is deprecated, use`programs.zsh.initContent` instead` during rebuild](#error-evaluation-warning-programszshinitextrais-deprecated-useprogramszshinitcontent-instead-during-rebuild)
    - [Error: `/home/<username>/<name>' would be clobbered` during rebuild (such as with hms)](#error-homeusernamename-would-be-clobbered-during-rebuild-such-as-with-hms)
    - [Weird keyboard layout during install](#weird-keyboard-layout-during-install)
  - [❄️ Note on the declarative aspects](#️-note-on-the-declarative-aspects)
  - [📝 Project Origin and Customization](#-project-origin-and-customization)
  - [Showcase](#showcase)
    - [Hyprland](#hyprland)
    - [KDE](#kde)
    - [Gnome](#gnome)
    - [XFCE](#xfce)
  - [Other resources](#other-resources)
    - [Structure](#structure)
    - [In-depth-files-expl](#in-depth-files-expl)
    - [Issues](#issues)
    - [Ideas](#ideas)
    - [Usage guide](#usage-guide)
    - [Wallpapers](#wallpapers)


## ✨ Features

### 🖥️ Adaptive Host Support: ### 
Define unique hardware parameters (monitors, theming, keyboard layout,  wallpapers, etc) per machine while keeping the core environment identical. All these customized options can be changed in the host-specific directory
- This allow to have a tailored experience right from the start,
- For reference look point ([5. Configure the host folder](#5-configure-the-hosts-folder)).
- A variables can be added anytime and it is automatically recognized. Then if it needs to be called it can be simply done by appending `vars.` to the name of the variable

---

### 📦 Package version and flatpak
Allow the user to define the version of various aspects and decide if some features are enabled:
- `flake.nix`: Nixpkgs stable (unstable is always at the latest)/home-manager/stylix,
  - These can be changed freely in the future to stay up to date.
- `configuration.nix`: stateVersion/homeStateVersion,
  - The first time it is a good idea to make them match the rest. However they should not be changed later. Basically they should be set at first build and then be left alone
- Flatpak (true/false)

To view the latest release numbers refer to the [release notes](https://nixos.org/manual/nixos/stable/release-notes)

---

### ❄️ Hybrid (declarative + non declarative for some modules) ###
  - Some modules are better customized using their official methods (aka not with nix-sintax).
  - In this case a `.nix` file applies a basic logic and/or source an external directory/file; while other files/directories handles the rest.
    - For a more in-depth explanation see [❄️ Note on the declarative aspects](#️-note-on-the-declarative-aspects)
 
---

### 🎨 Theming ## 
A base 16 colorscheme can be chosen before building (hosts-specific). The user may also chose whatever to enable catppuccin or not (along with the flavor and accent) [from the official repo](https://nix.catppuccin.com/).
- To view the possible flavor and accent colors refer to [(catppuccin palette)](https://catppuccin.com/palette/)
- The benefit over using a normal base16Theme of catppuccin is that these modules are tailored, meaning the colors are chosen by a human and not blindly applied by an algorithm, resulting in a more pleasant experience.

To see where this custom catppuccin is enabled it is enough to look at the "targets" section in `stylix.nix`, for example:

```nix
# If catppuccin is disabled then it is set to true, letting the base16Theme do it's job
# If catppuccin is enabled then it is set to false, letting catppuccinNix do it's job
alacritty.enable = !catppuccin;
```

- This should allow to configure almost everything globally right from the get go
  
---  

### 🖌️ Wallpaper(s) ## 
  
Wallpapers are defined to be hosts specific and they are tied to the monitor list.
- They automatically apply smartly in all desktop environments except xfce

- The first monitor get the first wallpaper, the second monitor the second wallpaper etc. 
  - In kde plasma the primary monitor override this settings. If nothing is done the behavior is as expected,
  -  If the "primary" monitor is changed in the system settings than it will get the first wallpaper in teh list. 
  
If someone prefer to set the wallpaper manually then it is possible in certain desktop environment:
- For hyprland they are set in hyprland-hyprpaper. Hyprland does not have an easy way to set the wallpaper so it is best to keep it as is
- XFCE is left as default to allow the guest user a stock experience.

#### kde-main.nix
Comment out or remove the specific lines that handles the wallpapers logic
```nix
# wallpaper = wallpaperFiles;
```

#### gnome-main.nix
Comment out or remove the specific lines that handles the wallpapers logic
```nix
# "org/gnome/desktop/background" = {            
#   picture-uri = "file://${wallpaperPath}";      
#   picture-uri-dark = "file://${wallpaperPath}"; 
#   picture-options = lib.mkForce "zoom";         
# };                                             

# "org/gnome/desktop/screensaver" = {             <-- OPTIONAL: REMOVE THIS TOO
#   picture-uri = "file://${wallpaperPath}";
# };
```
---

### 🪟 Multiple Desktop Environments

  - **Hyprland**: A modern, tile-based window compositor setup on Wayland. You can choose between 2 options:

    - **Hyprland + caelestia with quickshell**
    - **Hyprland + waybar**

  - **KDE Plasma**: A highly configurable desktop environment, with a launcher similar to windows
  - **Gnome**: A famous and simple desktop environment, with a launcher similar to macOS. Ubuntu/mint user are very used to it
  - **Cosmic**: A revisited gnome made from the company system76, known for being the creators of popOS
    - Cosmic as for now is highly unstable. Expect freezes, black screen while logging out, keybindings not working, etc etc 
  - **XFCE**: A lightweight, stable, and classic desktop experience.
    - For now xfce is enabled only if the `guest` user is enabled. 
  

You can enable or disable desktop environments (Hyprland, GNOME, KDE, etc.) by editing `variables.nix`. However, disabling the environment you are currently using requires caution to avoid being locked out of the system.

> **⚠️ Warning:** If you set your **current** desktop to `false` and run `nixos-rebuild switch`, the graphical interface will terminate immediately. You will be dropped into a TTY, and in some cases, your user shell may break, forcing you to recover via `root`.

#### ✅ The Safe Way (Prevent Lockouts)

When changing Desktop Environments, **do not** apply the config immediately. Instead, build it for the *next* boot. This ensures you can reboot cleanly into the new environment.

1. **Edit your config** (enable/disable the DE as needed).
2. **Build the bootloader only:**
```bash
cd ~/nixOS
sudo nixos-rebuild boot --flake .
```


3. **Reboot** your system.
4. **Finalize the setup:** Once logged into the new session, run your standard update command to apply Home Manager customizations (themes, keybindings, etc.):
```bash
sw && hms  # or any equivalent update alias
```

#### 🚨 Emergency Recovery (Stuck in TTY)

If you accidentally disabled your current desktop and `nixos-rebuild switch` kicked you out, you may find yourself in a text-only console (TTY). 
- If logging in as regular user work then rebuilding is enough

```bash
sw && hms  # or any equivalent update alias
```

If your normal user shell fails to log in, follow these steps:

1. **Login as Root:**
* **User:** `root`
* **Password:** (Same as your admin user, unless explicitly changed).


2. **Repair the System:**
Run the following commands to rebuild the system from the root user. Replace `<your-username>` with your actual folder name (e.g., `krit`).
```bash
# 1. Enter the NixOS directory
cd /home/<your-username>/nixOS

# 2. Allow root to access the user's git repo
nix-shell -p git --command "git config --global --add safe.directory '*'"

# 3. Rebuild the boot config for the next restart
nixos-rebuild boot --flake .

# 4. Reboot
reboot

```


3. **Finalize:** After rebooting, log in as your normal user and run `sw && hms` to restore your dotfiles.

#### 🛠️ Troubleshooting

**Issue: "File .../hyprland.conf would be clobbered"**
When re-enabling a desktop (especially Hyprland) after having it disabled, Home Manager might fail because a config file was left behind.

**Fix:** Remove the conflicting file manually and retry the build.

```bash
rm ~/.config/hypr/hyprland.conf
sw && hms
```

**Issue: Missing Personalization**

If you boot into a new desktop and it looks "vanilla" (missing keybindings or wallpapers), it usually means Home Manager hasn't run yet. Simply run your switch command (`sw && hms`) again to apply the user-level configurations.

---

### 👤 Ephemeral Guest User ### 
A specialized secure account for visitors (basic features):
  - **Login credentials**: both password and usernames are `guest`
  
  - **Restricted**: No `sudo` access and no permission to view nor modify the NixOS configuration.
  
  - **Essential Tools**: Pre-loaded with a Browser, File Manager, Text Editor, image viewer, archive manager, calculator.
  
  - **Forced desktop environment**: This user only has access to `xfce` and its default applications. If the guest tries to acces a non-allowed de/wm then the pc reboots automatically.
   -  Applications that require sudo priviliges either do not open or simply fail to do anything.
   - If you want the guest user to have access to all de then it is enough to remove all "rebooting" logic 
  
  - **Tailscale firewall**: This user does not have access to tailscale and can not ping even local ip regardless if tailscale is on or off
  
  - **Privacy Focused**: The entire user home folder (including browser cookies, sessions, and saved files) is wiped automatically on every reboot or shutdown (logging out keep the data).
    - For now this is achieved by using `tmpfs`. This tells that the user data (home path) is written on ram and not ssd/hdd.
      - This has 3 major advantages: 
        - Lifespan of the pc component (ram is rated to last more than disks)
        - Ensure privacy: Defining a script to delete the content in a disk is subject to silent fails. This means the data could not be completely removed. Ram is sure to be deleted once the pc restart 
      - The main disadvantage is a possible performance issues on system with low ram. 
        - The current config tells that the guest user can use up to a certain ram space. If a host has low ram it is possible to have freezes

- It is possible to change the  of the data deletion from ram to disk by changing `guest.nix`


```nix
# 🧹 EPHEMERAL HOME  <-- REMOVE/COMMENT OUT THIS ENTIRE BLOCK
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
```

Replace with the following block:
```nix
# 🧹 DISK-BASED AUTO-WIPE (Low RAM Alternative)
    # Wipes /home/guest at every boot before the login screen starts.
    systemd.services.wipe-guest-home = {
      description = "Wipe guest home directory on boot";
      wantedBy = [ "multi-user.target" ]; 
      before = [ "display-manager.service" "systemd-logind.service" ];
      serviceConfig = {
        Type = "oneshot";
        # Script to remove the folder and recreate it with correct permissions
        ExecStart = pkgs.writeShellScript "wipe-guest" ''
          # 1. Nuke the directory if it exists
          if [ -d /home/guest ]; then
            rm -rf /home/guest
          fi
          
          # 2. Recreate it fresh
          mkdir -p /home/guest
          
          # 3. Set ownership (guest:guest) and permissions (read/write only for user)
          chown ${toString guestUid}:${toString guestUid} /home/guest
          chmod 700 /home/guest
        '';
      };
    };
```


### 🏠 Home Manager Integration ### 
Fully declarative management of user dotfiles and applications.

### 🧇 Tmux ### 
Customized terminal multiplexer.

### 🌟 Zsh + Starship
Starship provide beautiful git status symbols, programming language symbols, the time, colors and many other features.

ZSH is hybrid:
- A nix files contains nix-specific aliases and behaviour
- It sources another file called `~/.zshrc_custom`
  - This allow the user to define aliases which are not nix-specific inside this custom file. 
  - This give the user the possibility to use the same zshrc for any other linux distro that it may have 


### 🦺 BTRFS snapshots
- Possibility to enable snapshots and define an host-specific retention policy

---


# 🚀 NixOS Installation Guide

Welcome! This guide will take you from a blank computer to a fully working NixOS desktop using our **Template Host**.

We use **Disko** to automate the complex disk partitioning steps (creating Btrfs subvolumes for snapshots), so you don't have to run manual formatting commands.

---

## 📦 Phase 1: Preparation

### 1. Download & Flash

1. **Download:** Get the **NixOS Minimal ISO** (64-bit Intel/AMD) from [nixos.org](https://nixos.org/download.html).
2. **Flash:** Use **Rufus,balena etcher or similar** to write the ISO to a USB stick.
* **Partition Scheme:** GPT
* **Target System:** UEFI (non-CSM)


3. **BIOS:** Ensure **Secure Boot** is Disabled and your BIOS is set to **UEFI** mode.

### 2. Boot & Connect

1. Insert the USB and boot your computer.
2. Select **"UEFI: [Your USB Name]"** from the boot menu.
3. Once the text console loads (`[nixos@nixos:~]$`):
* **WiFi:** Run `sudo nmtui`, select "Activate a connection", and pick your network.
* **Ethernet:** Should work automatically. verify with `ping google.com`.



---

## 💾 Phase 2: The Terminal Installation

### 1. Download the Config

We need to fetch the installer template.

```bash
nix-shell -p git
git clone https://github.com/nicolkrit999/nixOS.git
cd nixOS
```

### 2. Identify Your Disk

We must identify which drive to wipe. **Be careful here.**

```bash
lsblk
```

* Look for your main disk (e.g., `476G` or `931G`).
* Note the name: usually **`nvme0n1`** (for SSDs) or **`sda`**.

### 3. Create Your Host

Copy the template to a new folder for your machine. Replace `my-computer` with your desired hostname.
- The template include only a few enabled options, allowing a smaller and faster installation.
- Only the following features are enabled:
  - hyprland
  - alacritty as default terminal
  - firefox as default browser
  - vscode as default code editor
  - dolphin as default file manager
  - nord dark theme
  - us international keyboard layout 

```bash
cd hosts
cp -r template-host my-computer
cd my-computer
```

### 4. Configure the Drive

Tell the installer which disk to wipe.

```bash
nano disko-config.nix
```

* Find the line: `device = "/dev/nvme0n1";`
* Change it to **your actual drive name** found in step 2.
* **Save:** `Ctrl+O` -> `Enter` -> `Ctrl+X`

### 5. Configure Critical Variables

We only need to set the basics now. You can customize themes and wallpapers later in the GUI.

```bash
nano variables.nix
```

* **`user`**: Change `"template-user"` to your real username.
* **⚠️ CRITICAL:** Do not install as `template-user` and try to rename it later. You will lose access to your home folder. Set your real username **NOW**.
* **`system`**: The template is `x86_64-linux`. If you have a newer arm-based pc then `aarch_64`


You may also want to configure the keyboard. If you don't have us international you may boot into a wrong layout. Below there is an example with multiple layouts

```nix
 keyboardLayout = "us,ch,de,fr,it"; # 5 different layouts
  keyboardVariant = "intl,,,,"; # main variant + 4 commas (total 5 values, same as keyboardLayout)
```

- You will notice default settings for the monitor and a default wallpaper (either black or the default one of the de/wm you chose). This is expected because the `monitors` variable is not defined yet and the wallpaper logic rely on it.


### 6. Install (The Magic Step)

Run these three commands to format the drive and install the OS.

```bash
# 1. Partition & Mount (Wipes the drive!)
sudo nix run github:nix-community/disko -- --mode disko ./disko-config.nix

# 2. Generate Hardware Config (Captures CPU/Kernel quirks)
# We point this DIRECTLY to your host folder so the repo root stays clean
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos/hosts/my-computer

# 3. Install
cd ../..  # Go back to the repo root

# If for some reason you need the impure flag just add it at the end of the following command
nixos-install --flake .#my-computer
```

### 7. Finish

1. Set your **root password** when prompted at the end. Note the password is not displayed while typing
2. Type `reboot` and remove the USB stick.

---

## 🎨 Phase 3: Post-Install Setup

Congratulations! You are now logged into your new NixOS desktop.
- After installing the cosmic de setup dialog (if you enabled it) can appear. Either configure it regardless of which de you are on or close it
- If for any reason alacritty does not open `foot` is available and it's sure to work because it does not require any particular configuration

### 1. Move Config to Home

Your configuration is currently owned by `root` in a system folder. Let's move it to your home folder so you can edit it safely.

1. Open your terminal.
2. Move the config:
```bash
sudo mv /etc/nixos ~/nixOS
sudo chown -R $USER:users ~/nixOS
```



### 2. (Optional) Cleanup Unused Hosts

Now that you have your own host (`my-computer`), you might want to delete `template-host` or other examples to keep your folder clean.

Run this command inside `~/nixOS`:

```bash
(
  cd ~/nixOS || return
  printf "Enter hostnames to KEEP (space separated): "
  read -r INPUT
  
  if [ -z "$INPUT" ]; then
      echo "No input. Exiting."
      return
  fi

  SAFE_TO_DELETE=true
  for host in ${INPUT}; do
      if [ ! -d "hosts/$host" ]; then
          echo "Error: 'hosts/$host' not found."
          SAFE_TO_DELETE=false
      fi
  done

  if [ "$SAFE_TO_DELETE" = true ]; then
      echo "Cleaning up..."
      for dir_path in hosts/*; do
          [ -d "$dir_path" ] || continue
          dir_name=$(basename "$dir_path")
          
          matched=false
          for keep_name in ${INPUT}; do
              if [ "$dir_name" = "$keep_name" ]; then
                  matched=true
              fi
          done

          if [ "$matched" = false ]; then
              rm -rf "$dir_path"
          fi
      done
      echo "Done. Remaining hosts:"
      ls hosts/
  else
      echo "Aborting. No changes made."
  fi
)
```

*Example input: `my-computer` (This will delete every host except this one).*

---

## 🛠️ Phase 4: Customization


### Refine `variables.nix`


  * `gitUserName`: Github user name.
  
  * `gitUserEmail`: Github user e-mail.
  
  * `stateVersion` & `homeStateVersion`: Keeps your config stable (e.g., `25.11`).
  
  * `hyprland`: Whatever to enable hyprland or not

  * `caelestia`: Whatever to enable caelestia/quickshell or not
  
    ```nix
    # If you want hyprland with waybar
    hyprland = true;
    caelestia = false;

    # If you want hyprland with caelestia & quickshell
    hyprland = true;
    caelestia = true;
    ```

   * `gnome`: Whatever to enable gnome or not

   * `kde`: Whatever to enable kde or not

   * `cosmic`: Whatever to enable cosmic or not
  
  * `flatpak`: Whatever to enable support for flatpak
  
  * `term`: Default terminal, used for keybindings and tmux
    * Depending on the terminal it may be necessary to add an entry `set -as` to `tmux.nix`. This is necessary to tell tmux that the current terminal support full colors. 
  
  For example:
  
  ```nix
  set -as terminal-features ",xterm-kitty:RGB"
  ```

  * `browser`: Default browser. To make sure it work 100 write the name of the official package. Common options are the following (they match an existing package name)
    * google-chrome
    * firefox
    * chromium

  * `editor`: Default text/code editorTo make sure it work 100 write the name of the official package. Common options are the following (they match an existing package name)
    * vscode
    * code
    * code-cursor
    * neovim
    * vim
    * emacs
    * sublime
    * kate
    * gedit

  * `fileManager`: Default file manager. To make sure it work 100 write the name of the official package. Common options are the following (they match an existing package name)
    * dolphin (the pkgs.kdePackages portion is already handled. write only `dolphin`)
    * xfce.thunar
    * ranger
    * nautilus
    * nemo

  * `base16Theme`: which base 16 theme to use  
    * Reference https://github.com/tinted-theming/schemes/tree/spec-0.11/base16
  
  * `polarity`: Decide whatever to have a light or a dark theme in stylix.nix
    * This should make sense with the global base16 themes. This means a dark-coloured global theme should have a dark polarity and vice-versa
    * Currently it is used in the following files:
      * `qt.nix`, `kde/main.nix` 
  
  * `catppuccin`: Whatever to enable catppuccin theming or not. If disabled all the theming is done via the base theme. Note that some modules may require attention in order to be fully customized. For more information see [(the catppuccin features)](#-theming)
    
  * `catppuccinFlavor`: What catppuccin flavor to use
    * the flavor name should be all lowercase. frappé needs to be written without accent so  frappe
  
  * `catppuccinAccent`: What catppuccin Accent to use

  
  * `timezone`: Your system time zone (e.g., `Europe/Zurich`).
    * To choose the timezone refer to the [(IANA time zone database)](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) 
  
  * `weather` (waybar and kde-specific-optional): Location for the weather widget (e.g., `Lugano`).
  
  * `keyboardLayout`: Single or list of keyboard layout
  
  * `keyboardVariant`: Keyboard variant
    * If more layout are defined a comma is needed for each layout except the first one. For example:

```nix
 keyboardLayout = "us,ch,de,fr,it"; # 5 different layouts
  keyboardVariant = "intl,,,,"; # main variant + 4 commas (total 5 values, same as keyboardLayout)
```

  * `screenshots`: Setup the preferred directory where screenshots are put
    * Currently the path and shortcuts only work in hyprland and kde 

  * `snapshots`: Whatever to enable snapshots or not

  * `snapshotRetention`: How many snapshots to keep for a certain period
  
  * `tailscale`: Whatever to enable or disable the tailscale service.
    * "guest" user has this service disabled using a custom firewall rules in configuration.nix (host-specific)

  * `guest`: Whatever to enable or disable the guest user.
  
  * `zramPercent`: Ram swap to enhance system performance.

  * `monitors`: List of monitor definitions (resolution, refresh rate, position).
    * For a guide on how to set it up refer to the [(hyprland guide)](https://wiki.hypr.land/Configuring/Monitors/) 

* `wallpapers` : List of wallpapers corresponding to the monitors.
  * **How to get the values:**
  1. **`wallpaperURL`**: Nix requires a direct link to the raw image file. If using GitHub, standard links won't work. Copy your GitHub link and paste it into [(git-rawify)](https://git-rawify.vercel.app/) to get the correct "Raw" URL.
  2. **`wallpaperSHA256`**: Generate the hash by running this command in your terminal:

  * **Troubleshooting URLs**:
  If your URL contains special characters (like `%20` for spaces), the command might fail or return an "invalid character" error. To fix this, **wrap the URL in single quotes**:
  * ❌ *Fail:* `nix-prefetch-url https://example.com/my%20wallpaper.png`
  * ✅ *Success:* `nix-prefetch-url 'https://example.com/my%20wallpaper.png'`
  
```bash
nix-prefetch-url <your_raw_url>
```

  * `idleConfig` : Power management settings (timeouts for dimming, locking, sleeping).

#### An hosts variable config example:

```nix
{
  hostname = "template-host";
  system = "x86_64-linux";

  stateVersion = "25.11";
  homeStateVersion = "25.11";

  user = "template-user";
  gitUserName = "template-user";
  gitUserEmail = "template-user@example.com";

  hyprland = true;
  caelestia = false;

  gnome = false;
  kde = false;
  cosmic = false;

  flatpak = false;
  term = "alacritty";

  browser = "firefox";
  editor = "code";
  fileManager = "dolphin";

  base16Theme = "nord";
  polarity = "dark";
  catppuccin = false;
  catppuccinFlavor = "mocha";
  catppuccinAccent = "sky";

  timeZone = "Europe/Zurich";
  weather = "Lugano";
  keyboardLayout = "us";
  keyboardVariant = "intl";

  screenshots = "$HOME/Pictures/screenshots";

  tailscale = false;
  guest = false;
  zramPercent = 25;

  monitors = [
  ];

  wallpapers = [
    {
      wallpaperURL = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/os/nix-black-4k.png";
      wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
    }
  ];

  idleConfig = {
    enable = true;
    dimTimeout = 600;
    lockTimeout = 1800;
    screenOffTimeout = 3600;
    suspendTimeout = 7200;
  };
}
```

### Setup `local-packages.nix`
- It contains packages that are intended to only be installed in that specific hosts
  - add as needed

### Setup `flatpak.nix`
- It contains flatpak packages that are intended to only be installed in that specific hosts
  - add as needed


### Setup (optional) `modules.nix`
This file contains specific "Power User" configurations and aesthetic tweaks that may vary significantly between machines (e.g., desktop vs. laptop).
- See below for a guide


### Setup (optional) `home.nix`
This file contains specific home-manager aspects that are related only to a certain host. It complement well the global home.nix
- See below for a guide

### Setup (optional) `host-modules` folder
- This is a folder that can contains modules that can be configured with home-manager but that are only active on a certain host.
  - This help to keep clean the original home-manager/modules folder 

- See below for a guide

---

## Phase 5: Setup optional host-specific files and directories

### 1. (Optional) Customize the host-specific `modules.nix`

* **How it works**: The system checks if `hosts/<your_hostname>/modules.nix` exists. If it does, it merges these variables with your main configuration.
  * The file is included in the template-host, with a sample configuration. This provide a starting base. If not needed it can be deleted at any moment and all the fallback will apply 
* **The Safety Net**: If this file is missing (or if you omit specific variables), the system applies a **safe fallback**. This ensures the build never fails, even if you don't define these complex options.

* If you add any option then ideally a fallback should be defined in the target nix file

**Available Options:**

| Variable                       | Description                                                                                                           | Fallback (If undefined)                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **`hyprlandWorkspaces`**       | Binds specific workspaces to specific monitor ports (e.g., "1 on DP-1").                                              | **Auto-detect:** Workspaces open on the monitor with the mouse cursor.            |
| **`hyprlandWindowRules`**      | Binds specific applications to specific workspaces (e.g., "Code opens on workspace 2").                               | **None:** Applications open on the currently focused workspace.                   |
| **`kdeMice` / `kdeTouchpads`** | Applies strict settings (accel profile, speed) to specific Hardware IDs in KDE.                                       | **Plug & Play:** KDE applies standard default settings to all mice.               |
| **`waybarWorkspaceIcons`**     | Maps specific workspace numbers to custom icons (e.g., "8" -> "Terminal Icon").                                       | **Numbers:** Waybar simply displays the workspace number (1, 2, 3...).            |
| **`waybarLayoutFlags`**        | Replaces keyboard layout text codes with emojis (e.g., "en" -> "🇺🇸").                                                  | **Text Codes:** Waybar displays the ISO code (en, it, de).                        |
| **`starshipZshIntegration`**   | Controls if Starship is auto-loaded in Zsh (`eval "$(starship init zsh)"`). Set to `false` if you manually source it. | **`true` (Enabled):** Starship loads automatically for a standard setup.          |
| **`nixImpure`**                | If `true`, the `sw` and `upd` aliases run with `--impure` (needed for unversioned files/secrets).                     | **`false` (Pure):** Aliases use standard `nh` commands (or pure `nixos-rebuild`). |


#### `modules.nix` Example

Modify this file in `hosts/<your_hostname>/modules.nix` to override the defaults.

```nix
{
  # ---------------------------------------------------------------------------
  # 🖥️ HYPRLAND WORKSPACES
  # ---------------------------------------------------------------------------
  # Strict monitor bindings. 
  # Use `hyprctl monitors` to find your specific monitor names (e.g., DP-1, eDP-1).
  # Int his example each monitor get 5 workspaces
  hyprlandWorkspaces = [
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

  # Forces specific apps to always open on specific workspaces
  # To see the right class name, use `hyprctl clients` command and look for "class:"
  # if you want the avoid switching to that workspace when opening just add "silent" after the number
  hyprlandWindowRules = [
    "workspace 2, class:^(code)$"
    "workspace 7, class:^(chromium-browser)$"
    "workspace 8, class:^(Alacritty)$"
    "workspace 8, class:^(kitty)$"
    "workspace 9, class:^(vesktop)$"
    "workspace 10, class:^(org.telegram.desktop)$"
  ];

  # ---------------------------------------------------------------------------
  # 🖱️ KDE INPUT DEVICES
  # ---------------------------------------------------------------------------
  # Strict hardware IDs for Plasma Manager.
  # Use `cat /proc/bus/input/devices` to find Vendor/Product IDs.
  kdeMice = [
    {
      enable = true;
      name = "Logitech G403"; 
      vendorId = "046d"; 
      productId = "c08f"; 
      acceleration = -1.0;
      accelerationProfile = "none";
    }
  ];

  # Leave empty for desktop PCs
  kdeTouchpads = [ ];

  # ---------------------------------------------------------------------------
  # 🧩 WAYBAR ICONS & FLAGS
  # ---------------------------------------------------------------------------
  # 1. Custom Workspace Icons
  # Some ide do not show the actual icons depending on which fonts is configured
  waybarWorkspaceIcons = {
    "1" = "";
    "7" = ":"; # Browser
    "8" = ":"; # Terminal
    "9" = ":"; # Music
    "10" = ":"; # Chat
    "magic" = ":";
  };

  # 2. Custom Layout Flags (Format: "format-<layout_code>")
  waybarLayoutFlags = {
    "format-en" = "🇺🇸";
    "format-it" = "🇮🇹";
    "format-de" = "🇩🇪";
  };

  # The fallback is true
  starshipZshIntegration = true;

  # The fallback is false
  nixImpure = false;
}
```



### 2. (optional) Other files that may require manual attention
- These files can be modified also after building.
  - These are files that one most likely will want to configure right from the beginning because they cause a "wrong" experience
- Unlike `modules.nix` these are files so personal and/or so big that are better changed in their original module file

#### ~/nixOS/home-manager/modules/firefox.nix and ~/nixOS/home-manager/modules/chromium.nix
- They contains personalized aspects like homepage, toolbars visible items, extensions. One may want to change them


#### ~/nixOS/home-manager/modules/neovim.nix/
- It contains my neovim specific behavior
- To start it is suggested to replace the entire content of the file with a more basic one

```nix
{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
    ];
  };
}
```


#### ~/nixOS/home-manager/modules/zathura.nix/
- The font size and family is hardcoded. One may want to change it

#### ~/nixOS/nixos/modules/mime.nix/
- It define system-wide default applications when a user perform a certain action, such as clicking open directory, or a link

---

### 3. (Optional) Customize the host-specific `home.nix`

This file allows you to manage user-specific configurations that should **only** apply to the current machine. Unlike `local-packages.nix` (which installs system-wide packages), this file uses Home Manager, allowing you to configure dotfiles, environment variables, and symlinks.

**Common Use Cases:**

| Feature                     | Description                                                                                     | Example Usage                                                                               |
| --------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **`home.packages`**         | Installs packages for the user only on this host. It also include a block for unstable packages | Installing `blender` or `gimp` only on a powerful desktop PC.                               |
| **`xdg.userDirs`**          | Overrides the default `~/` folders.                                                             | Hiding unused folders like `~/Public` or `~/Templates` on a laptop.                         |
| **`home.file`**             | Links a package or file to a specific path.                                                     | Linking `jdtls` to `~/tools/jdtls` so your Neovim config works the same across all distros. |
| **`home.sessionVariables`** | Defines shell variables for this host only.                                                     | Setting `JAVA_HOME` or `JDTLS_BIN` only on machines used for development.                   |
| **`home.activation`**       | Activate certain functions such as creating customs folders                                     | Make sure certain directories exist only for that host                                      |

#### `home.nix` Example

Create or modify `hosts/<your_hostname>/home.nix`:

```nix
{ pkgs, 
  pkgs-unstable, 
  lib, 
  ... 
}:
{
  # ---------------------------------------------------------------------------
  # 🏠 HOST-SPECIFIC HOME CONFIGURATION
  # ---------------------------------------------------------------------------
  # This file is automatically imported if it exists.

  # 1. Install specific tools
  home.packages = (with pkgs; [
    gimp
    blender
  ])
  ++ (with pkgs-unstable; [
    vscode
  ]);

  # 2. XDG Overrides
  # Folders set to 'null' will be disabled/hidden
  xdg.userDirs = {
    publicShare = null;
    templates = null;
  };

  # 3. Development Tools & Paths
  # Creates a fixed path for JDTLS so external configs (like zshrc_custom) can rely on it.
  home.file."tools/jdtls".source = pkgs.jdt-language-server;

  # 4. Environment Variables
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk25}";
    JDTLS_BIN = "${pkgs.jdt-language-server}/bin/jdtls";
  };

  # 5. other things
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';
  };
}
```


### 4. (Optional) Customize the host-specific `host-modules` directory
- This folder can contain any .nix file that you would use as a home-manager modules. The only difference is that they are put inside this folder
- When a new file is added it needs to be defined in default.nix. For example:

```bash
{
  imports = [
    ./alacrity.nix
  ];
}
```

If a module here contains aspects such as networking, boot, user or similar then home-manager alone can not configure those aspects and a rebuild would fail. To solve that specific modules needs to be added to the host `configuration.nix`. En example block is this:

```bash
imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./local-packages.nix

    # Secrets Management (not added to GitHub)
    (import /etc/nixos/secrets/secrets.nix)

    # Flatpak support
    ./flatpak.nix

    # Core imports
    ../../nixos/modules/core.nix

    # These are manually imported here because they contains aspects that home-manager can not handle alone
    ./host-modules/logitech.nix # boot
  ];
```




---

## 🔄 Daily Usage & Updates

Whenever you edit a file, use these aliases to apply your changes. You don't need to type the long `nixos-rebuild` command.

The normal switch command handle both a system and a home-manager rebuild.

| Alias     | Command                 | Description                                                            |
| --------- | ----------------------- | ---------------------------------------------------------------------- |
| **`sw`**  | `nh os switch`          | **System Rebuild**. Rebuild everything                                 |  |
| **`upd`** | `nh os switch --update` | **System Update**. Downloads the latest package versions and rebuilds. |


## ❓ Troubleshooting

### Error: `path '.../hardware-configuration.nix' does not exist`

**Cause:** Nix Flakes only see files that are tracked by Git (you skipped `git add -f` in step 4).
**Fix:** Force add the file to git:

```bash
git add -f hosts/<hostname>/hardware-configuration.nix
```

### Error: `home-manager: command not found`

**Cause:** You removed the system-wide package, but the user-level package hasn't installed yet.
**Fix:** Run the bootstrap command again (step 6 part 2):

```bash
home-manager switch
```

### Error: `permission denied` opening `flake.lock`

**Cause:** You cloned the repo as root but are trying to build as a user.
**Fix:** Fix ownership:

```bash
# This smart command automatically fetch the useranem so no changes are needed
sudo chown -R $USER:users ~/nixOS
```

### Error: `returned non-zero exit status 4` during rebuild

**Cause:** Common during massive updates. System built fine but failed to restart a service (often DBus).
- Some time the rebuild seems stuck.
  - Tough it may also be a true stuck chanches are that the system correctly builded but can not show this in the cli 

**Fix:** Safe to ignore. Reboot your computer.

### Error: `evaluation warning: `programs.zsh.initExtra` is deprecated, use `programs.zsh.initContent` instead` during rebuild

**Cause:** This seems to be a mismatch on what some inputs in flake.nix want vs what other inputs wants

**Fix:** Safe to ignore (for now)

### Error: `/home/<username>/<name>' would be clobbered` during rebuild (such as with hms)

**Cause:** Sometime even if it is forced nix refuse to build because a certain file/directory would be clobbered. This happen especially in `gtk* files`

**Fix:** Remove the file/directory interested and rebuild

### Weird keyboard layout during install
This is a problem that i encountered. It may have been user error but i write it here just to be safe.

Even tough i selected us international during the gui installer once rebooted into cli (since i selected no desktop) i was greeted with all mixed keys. Meaning what i saw on the physical keyboard were not the keys that were pressed.
- For me the layout that nixOS had at that moment in time was `dvorak`
- This is solvable by manually converting the keyboards or just ask an ai what keys to press on a dvorak layout to actually input what the user wants. After the user login is successful input the following command `loadkeys <layout>` (until this command run successfully the keyboard layout is still `dvorak`). After this the problem should be solved and since the layout are chosen declarative this should not be a problem anymore



## ❄️ Note on the declarative aspects

Some modules are better customized using their official methods.

These modules uses a dedicated `*.nix` file where it defines that the main configuration is taken from another place and unified with the respective `*.nix` file

These blocks are configured in such a way that allow 2 scenario:

1: The user has a customized setup (either with stowing from another github repo) or directly in the original intended location.
  - In this case there is an hybrid environment. Meaning everything defined in both `*.nix` files and the original file/directory apply

2: The user does not have a customized setup the original location is either empty or default (after installing the program)
  - In this case the behaviour in `*.nix` apply but since the rest is default it is like not applying it at all

Currently this behaviour happens for 2 programs: 
- **Neovim**: 
  - Nix reference: `neovim.nix`
  - Original reference: `~/.config/nvim/*`
- **zsh**: 
  - Nix reference: `zsh.nix`
  - Original reference: `~/.zshrc_custom`



## 📝 Project Origin and Customization

This NixOS configuration project began as local copy and adaptation of the excellent work by **Andrey0189** from their repository: [https://github.com/Andrey0189/nixos-config-reborn](https://github.com/Andrey0189/nixos-config-reborn).

I would like to extend my thanks to **Andrey0189** for providing a robust starting point.

While the original repository laid the foundation, this setup has been **heavily customized** and expanded over time to suit my personal needs and workflows. Key changes include:

* **Heavily improved hosts variables**: Modified the hosts directory such that it contains many more aspects that can differs from host to host
* **Multiple Desktop Environments**: Added configuration and support for multiple desktop environments
* **Ephemeral Guest User**: Implemented a secure, non-persistent guest account with automatic home directory wiping on reboot.
* **Theming Overhaul**: Integrated a base 16 colorscheme selection alongside Catppuccin official theming via `stylix`.
* **Hybrid Declarative Aspects**: Detailed and implemented a hybrid approach for tools like Neovim and Zsh, allowing for declarative configuration while respecting and integrating official, non-declarative customization methods.
* **Flake Configuration**: Enhanced the `flake.nix` file to suit the logic that there are many more variables that differs from hosts to hosts

This README documents the final, highly customized iteration of that initial framework.

The LICENCE.txt file is copied from the original repo and should respect the GPLv3 terms
- If there are any problems reach me by e-mail githubgitlabmain.hu5b7@passfwd.com


## Showcase
These photos contains the following options:
```nix
guest = true;
base16Theme = "nord";
polarity = "dark";
catppuccin = false;
catppuccinFlavor = "mocha"; 
catppuccinAccent = "sky"; 
```


### Hyprland
![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-showcase.png)

### KDE
![kde-showcase](./Documentation/showcase-screenshots/kde-showcase.png)

### Gnome
![gnome-showcase](./Documentation/showcase-screenshots/gnome-showcase.png)

### XFCE
![xfce-showcase](./Documentation/showcase-screenshots/xfce-showcase.png)




## Other resources
### [Structure](./Documentation/structure/Structure.md)
This folder contains the entire structure of the project, with a general of every single file

### [In-depth-files-expl](./Documentation/in-depth-files-expl/files-expl.md)
This folder contains an in-depth explanation of files that could be difficult to understand

### [Issues](./Documentation/issues/issues.md)
This folder contains an explanation of the issues that i noticed and that should eventually be resolved
- Issues include both warnings than critical one

### [Ideas](./Documentation/ideas/ideas.md)
This folder contains ideas that i think may benefit the project


### [Usage guide](./Documentation/usage/usage-guide)
This folder contains a guide on how basic aspects should be implemented, such as:
- Creating a system-wide module
- Create a general home-manager modules that apply to all hosts
- Create a host-specific home-manager modules
- Theming guide

### [Wallpapers](./wallpapers/credits)
- This folder contains some wallpapers allowing for an easy setup using raw url.
  - For each asset not mine a reference to the original author(s) is included in the document 






