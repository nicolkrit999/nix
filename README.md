# ❄️ Personal NixOS Config
![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-showcase.png)

- [❄️ Personal NixOS Config](#️-personal-nixos-config)
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
  - [🚀 Installation](#-installation)
    - [0. Prerequisites](#0-prerequisites)
    - [1. Install NixOS](#1-install-nixos)
    - [2. Clone the Repository](#2-clone-the-repository)
    - [3. Create Your Host Configuration (optional)](#3-create-your-host-configuration-optional)
    - [4. Import Hardware Configuration](#4-import-hardware-configuration)
    - [5. Configure the hosts folder](#5-configure-the-hosts-folder)
      - [`variables.nix`](#variablesnix)
      - [An hosts variable config example:](#an-hosts-variable-config-example)
      - [`local-packages.nix`](#local-packagesnix)
      - [`flatpak.nix`](#flatpaknix)
      - [`modules.nix`](#modulesnix)
      - [`home.nix`](#homenix)
    - [6. (Optional) Customize the host-specific `modules.nix`](#6-optional-customize-the-host-specific-modulesnix)
      - [`modules.nix` Example](#modulesnix-example)
    - [7. (optional) Other files that may require manual attention](#7-optional-other-files-that-may-require-manual-attention)
      - [~/nixOS/home-manager/modules/firefox.nix and ~/nixOS/home-manager/modules/chromium.nix](#nixoshome-managermodulesfirefoxnix-and-nixoshome-managermoduleschromiumnix)
      - [~/nixOS/home-manager/modules/neovim.nix/](#nixoshome-managermodulesneovimnix)
      - [~/nixOS/home-manager/modules/zathura.nix/](#nixoshome-managermoduleszathuranix)
      - [~/nixOS/nixos/modules/mime.nix/](#nixosnixosmodulesmimenix)
    - [8. (Optional) Customize the host-specific `home.nix`](#8-optional-customize-the-host-specific-homenix)
      - [`home.nix` Example](#homenix-example)
    - [9. First Time Build](#9-first-time-build)
  - [🔄 Daily Usage](#-daily-usage)
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


## ✨ Features

### 🖥️ Adaptive Host Support: ### 
Define unique hardware parameters (monitors, theming, keyboard layout,  wallpapers, etc) per machine while keeping the core environment identical. All these customized options can be changed in the host-specific `variables.nix`
- This allow to have a tailored experience right from the start,
- For reference look point ([5. Configure the host folder](#5-configure-the-hosts-folder)).

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
- They automatically apply smartly in all desktop environments except xfce and cosmic.

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

  - **Hyprland + Waybar**: A modern, tile-based window compositor setup on Wayland.
  - **KDE Plasma**: A highly configurable desktop environment, with a launcher similar to windows
  - **Gnome**: A famous and simple desktop environment, with a launcher similar to macOS. Ubuntu/mint user are very used to it
  - **Cosmic**: A revisited gnome made from the company system76, known for being the creators of popOS
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
  
  - **Forced desktop environment**: This user only has access to `xfce` and its default applications. Applications that require sudo priviliges either do not open or simply fail to do anything.
  
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

---

## 🚀 Installation

If the setup is installed completely (every feature enabled) it is suggested to have at least 128 gb of storage if the intent is to use it as main distro. For the installation expect anywhere from 20 to 50 gb. The rest is for user storage, and having at least 60 gb free in my opinion is a must in 2025



### 0. Prerequisites
- Ensure `secure boot` is disabled in the bios
- Ensure that the boot is in `UEFI` mode (not legacy/csm)

- If for some reason you want to skip this setup then see the step below to revert to systemd

To get started with this setup, follow these steps:

### 1. Install NixOS
Follow the [NixOS Installation Guide](https://nixos.org/manual/nixos/stable/#sec-installation).

There is a phenomena called "the 46% ghost". For some reason nixOS during it's installation likes to spend a lot of time at 46% progress, and the logs are not very descriptive. Do not worry if it seems stuck, it will eventually progress. This part can take a lot of time, just be patient.

**Recommended Install Settings if using nixOS gui installer:**

If a section is not included here then it does not matter since it will be changed later when the system build
* **Desktop Environment:** Select **No desktop environment** (selecting one would just install something that is later uninstalled when building)
* **Software:** Check **Allow unfree software** (tough this settings is enabled in my config for the first time installation to be successful it is needed)
* **Swap:** Select **No swap** (unless you have very low RAM)

**A note on grub:**
Since grub is defined and systemd is explicitely disabled in `/nixOS/nixos/boot.nix` a few steps to ensure that the EFI partitions are correctly should be made when the gui ask for partitioning, otherwise grub will fail to install. The steps below explains how to do it as well as the alternative of going back to systemd

During the **Partitioning** screen in the installer:

1.  **Select "Manual Partitioning"** (recommended for GRUB control) or ensure the automatic scheme creates an **EFI System Partition**.
2.  **Verify the ESP (EFI System Partition):**
    * **Size:** At least **512 MB** (100MB is the minimum, but 512MB is a better idea).
    * **File System:** `FAT32`.
    * **Mount Point:** `/boot` (NixOS default).
    * **Flags:** `boot`, `esp`.

**Why is this check necessary:**
`boot.nix` sets `grub.efiSupport = true;` and `grub.device = "nodev";`. This tells NixOS to look for an EFI partition to store the GRUB bootloader files. If the installer doesn't create this partition (or if it's too small), the rebuild will fail with as it "cannot find EFI directory" error.

**An alternative (reverse to systemd):**
To use systemd instead of grub it is enough to change `/nixOS/nixos/boot.nix` (of course after cloning the repo), see step [Clone the Repository](#2-clone-the-repository).

After cloning delete all it's content (brackets included) and put the following:

One can switch back to grub at anytime

```nix 
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```


**Recommended Install Settings if using a minimal install:**
* **Keyboard Layout:** Run `loadkeys <layout>` (e.g., `loadkeys us`) immediately.
* **Partitioning (Manual CLI):**
  Since this config uses GRUB with specific requirements, you must manually create a GPT partition table with a 512MB EFI partition.

  1. **Identify your disk** (e.g., `/dev/nvme0n1` or `/dev/sda`):
     ```bash
     lsblk
     ```
  2. **Partition the disk** (replace `<disk>` with your actual drive, e.g., `/dev/nvme0n1`):
     ```bash
     # Create a new GPT partition table
     parted <disk> -- mklabel gpt

     # 1. Create EFI Partition (512MB, FAT32)
     parted <disk> -- mkpart ESP fat32 1MiB 512MiB
     parted <disk> -- set 1 esp on

     # 2. Create Root Partition (Rest of the disk, EXT4)
     parted <disk> -- mkpart primary ext4 512MiB 100%
     ```
  3. **Format the partitions**:
     ```bash
     # Format EFI as FAT32
     mkfs.fat -F 32 -n boot <disk>p1  # (Use p1 for nvme, 1 for sda)

     # Format Root as EXT4
     mkfs.ext4 -L nixos <disk>p2      # (Use p2 for nvme, 2 for sda)
     ```
  4. **Mount the partitions**:
     *Crucial Step:* NixOS typically mounts the EFI partition to `/boot` for GRUB.
     ```bash
     # Mount Root
     mount /dev/disk/by-label/nixos /mnt

     # Create boot directory
     mkdir -p /mnt/boot

     # Mount EFI
     mount /dev/disk/by-label/boot /mnt/boot
     ```
  5. **Generate Config**:
     ```bash
     nixos-generate-config --root /mnt
     ```

### 2. Clone the Repository
Open a terminal in your fresh install:

```bash
nix-shell -p git --run "git clone https://github.com/nicolkrit999/nixOS.git"
cd nixOS/
````

### 3. Create Your Host Configuration (optional)
I provided with a sample hosts configuration `~/nixOS/hosts/template-host `
- This host contains a very simple configuration, with only hyprland enabled, alacritty as default terminal, nord as base16Theme, us as keyboard layout, already defined wallpapers. The other aspects can be changed later
  - Using this host as a starting point allow for a fast first-time deployment  

If you intend for your computer to **not** be named `template-host` (most probably), create a new host folder by copying the reference template:

```bash
cd ~/nixOS/hosts
cp -r template-host <your_hostname>
cd <your_hostname>
```

After this is done it is needed to modify inside `flake.nix` the `hostNames` list.
  - This list should contains the same name of all the hosts present inside the hosts directory.
    - If the hostname is not added in this list then it's entire configuration is ignored and build would not work if it contains the missing hostname in the command

```nix
hostNames = [
  "template-host" # <-- replace with the chosen hostname
];
```  

### 4. Import Hardware Configuration

Copy the hardware scan generated during installation into your host folder:
- During the previous step the other hosts hardware-configuration.nix got copied. Now since it is overwritten if asked accept when prompted to replace the file

```bash
# This assume the current terminal path is ~/nixOS/hosts/<hostname>/
cp /etc/nixos/hardware-configuration.nix .
# Important: Git must track this file for Flakes to see it. Add it before building
# The flag -f means it track it regardless .gitignore rules (if presents)
git add -f hardware-configuration.nix
```

### 5. Configure the hosts folder
#### `variables.nix`

This file contains all the aspects that may change from host to host.

* Changes made here allow you to have different environments that share the same base code.
* For example: on a desktop PC you might disable the `guest` user, while on a laptop you might enable it.



**Variables to define:**
To have a working setup, every single variable needs to be defined. If a variable is missing, the build will fail.

> **⚠️ CRITICAL WARNING: Edit BEFORE you build!**
> Do not blindly install the `template-host` configuration with the intention of changing the username later.
> **The Trap:**
> NixOS is declarative. It does not "rename" users; it simply ensures the users you declared exist.
> 1. If you install as `template-user` first, your data is stored in `/home/template-user`.
> 2. If you later change the variable to `user = "francesco"`, NixOS will create a **brand new** user.
> 3. **The Result:** You will end up with two home folders. Your old data stays in `/home/template-user` (which you can no longer log into easily), and you will be logged into a completely empty `/home/francesco`.
> 
> 
> **The Fix:**
> Always set your real `user`, `hostname`,  **before** running your first installation. The others can be changed later

  * `hostname` : Must match the folder name you created in Step [ 3 (create your hostname)](#3-create-your-host-configuration-optional).
  
  * `system`: Architecture (e.g., `x86_64-linux`).
  
  * `user`: Your desired username.

  * `gitUserName`: Github user name.
  
  * `gitUserEmail`: Github user e-mail.
  
  * `stateVersion` & `homeStateVersion`: Keeps your config stable (e.g., `25.11`).
  
  * `hyprland`: Whatever to enable hyprland or not

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
  gnome = false;
  kde = false;
  cosmic = false;

  flatpak = false;
  term = "alacritty";

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
    {
      wallpaperURL = "https://raw.githubusercontent.com/HyDE-Project/hyde-themes/Catppuccin-Mocha/Configs/.config/hyde/themes/Catppuccin%20Mocha/wallpapers/switch_swirl.jpg";
      wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
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

#### `local-packages.nix`
- It contains packages that are intended to only be installed in that specific hosts
  - add as needed

#### `flatpak.nix`
- It contains flatpak packages that are intended to only be installed in that specific hosts
  - add as needed


#### `modules.nix`
This file contains specific "Power User" configurations and aesthetic tweaks that may vary significantly between machines (e.g., desktop vs. laptop).


#### `home.nix`

---

### 6. (Optional) Customize the host-specific `modules.nix`

* **How it works**: The system checks if `hosts/<your_hostname>/modules.nix` exists. If it does, it merges these variables with your main configuration.
  * The file is included in the template-host, with a sample configuration. This provide a starting base. If not needed it can be deleted at any moment and all the fallback will apply 
* **The Safety Net**: If this file is missing (or if you omit specific variables), the system applies a **safe fallback**. This ensures the build never fails, even if you don't define these complex options.

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
  starshipZshIntegration = false;

  # The fallback is false
  nixImpure = true;
}
```



### 7. (optional) Other files that may require manual attention
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

### 8. (Optional) Customize the host-specific `home.nix`

This file allows you to manage user-specific configurations that should **only** apply to the current machine. Unlike `local-packages.nix` (which installs system-wide packages), this file uses Home Manager, allowing you to configure dotfiles, environment variables, and symlinks.

**Common Use Cases:**

| Feature                     | Description                                                 | Example Usage                                                                               |
| --------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **`home.packages`**         | Installs packages for the user only on this host.           | Installing `blender` or `gimp` only on a powerful desktop PC.                               |
| **`xdg.userDirs`**          | Overrides the default `~/` folders.                         | Hiding unused folders like `~/Public` or `~/Templates` on a laptop.                         |
| **`home.file`**             | Links a package or file to a specific path.                 | Linking `jdtls` to `~/tools/jdtls` so your Neovim config works the same across all distros. |
| **`home.sessionVariables`** | Defines shell variables for this host only.                 | Setting `JAVA_HOME` or `JDTLS_BIN` only on machines used for development.                   |
| **`home.activation`**       | Activate certain functions such as creating customs folders | Make sure certain directories exist only for that host                                      |

#### `home.nix` Example

Create or modify `hosts/<your_hostname>/home.nix`:

```nix
{ pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # 🏠 HOST-SPECIFIC HOME CONFIGURATION
  # ---------------------------------------------------------------------------
  # This file is automatically imported if it exists.

  # 1. Install specific tools
  home.packages = with pkgs; [
    gimp
    blender
  ];

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


### 9. First Time Build

This setup contains lot of packages, dependencies and similar so first time build can take some times depending on internet speed

Run the following commands to install the system and user configurations.

**Replace `<hostname>` with the hostname defined in `flake.nix`.**

- Remember that the hostname in `flake.nix` hosts sections and the actual directory name inside the parent `hosts` directory should match.

```bash
cd ~/nixOS/

# 1. Build the System (Root Level)
# For example: sudo nixos-rebuild switch --flake .#template-host
sudo nixos-rebuild switch --flake .#<hostname>

# 2. Build the Home (User Level)
home-manager switch
```

*(Note: Use `.#<hostname>` for Home Manager as well, as the flake outputs are keyed by hostname.)*

-----

## 🔄 Daily Usage

Once installed, you can switch the git remote to SSH (optional) (this assume you already added the hosts-specific ssh key to github) and use the convenient aliases for maintenance (if you are `krit`). This avoid asking the github password each time a rebuild is needed.
- If you are not krit then the only way to allow this is to fork the repository and change the url to your github username
  - The username is visibile in the link of the repo once it is forked 

```bash
# For example: git remote set-url origin git@github.com:nicolkrit999/nixOS.git
git remote set-url origin git@github.com:<github-username>/nixOS.git
```

**Maintenance Aliases:**

These aliases have or misses the `--impure` flag in a smart way 

| Command | Action                  | Description                                                                   |
| :------ | :---------------------- | :---------------------------------------------------------------------------- |
| # `sw`  | `nh os switch`          | **System Rebuild**. Applies changes to `configuration.nix` or system modules. |
| # `hms` | `nh home switch`        | **Home Rebuild**. Applies changes to Home Manager (dotfiles, themes).         |
| # `upd` | `nh os switch --update` | **System Update**. Updates `flake.lock` inputs and rebuilds the system.       |

-----

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






