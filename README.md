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
      - [Host-specific home-manager modules](#host-specific-home-manager-modules)
      - [Host-specific general home-manager modules tweaks](#host-specific-general-home-manager-modules-tweaks)
    - [❄️ Hybrid (declarative + non declarative for some modules)](#️-hybrid-declarative--non-declarative-for-some-modules)
    - [🎨 Theming](#-theming)
    - [🖌️ Wallpaper(s)](#️-wallpapers)
      - [kde-main.nix](#kde-mainnix)
      - [gnome-main.nix](#gnome-mainnix)
    - [niri-main.nix](#niri-mainnix)
    - [cosmic-main.nix](#cosmic-mainnix)
    - [🪟 Multiple Desktop Environments](#-multiple-desktop-environments)
      - [✅ The Safe Way (Prevent Lockouts)](#-the-safe-way-prevent-lockouts)
      - [🚨 Emergency Recovery (Stuck in TTY)](#-emergency-recovery-stuck-in-tty)
      - [🛠️ Troubleshooting](#️-troubleshooting)
    - [👤 Ephemeral Guest User](#-ephemeral-guest-user)
    - [🏠 Home Manager Integration](#-home-manager-integration)
    - [🧇 Tmux](#-tmux)
    - [🌟 Multiple shells + Starship](#-multiple-shells--starship)
    - [🦺 Optional BTRFS snapshots](#-optional-btrfs-snapshots)
    - [❔ SOPS-nix support](#-sops-nix-support)
    - [📦 Cachix support](#-cachix-support)
    - [🧑‍🍳 Denix support](#-denix-support)
    - [🖥️ Multi-architecture support](#️-multi-architecture-support)
- [🚀 NixOS Installation Guide](#-nixos-installation-guide)
  - [📦 Phase 1: Preparation](#-phase-1-preparation)
    - [1. Download \& Flash](#1-download--flash)
    - [2. Boot \& Connect](#2-boot--connect)
  - [💾 Phase 2: The Terminal Installation](#-phase-2-the-terminal-installation)
    - [1. Download the Config](#1-download-the-config)
    - [2. Identify Your Disk](#2-identify-your-disk)
    - [3. Create Your Host and import the chosen disko-config](#3-create-your-host-and-import-the-chosen-disko-config)
    - [4. Configure the Drive](#4-configure-the-drive)
      - [Option A: Standard (No Encryption)](#option-a-standard-no-encryption)
      - [Option B: Secure (LUKS + TPM 2.0)](#option-b-secure-luks--tpm-20)
    - [5a. Configure Critical Variables](#5a-configure-critical-variables)
    - [5b. Enable suggested modules](#5b-enable-suggested-modules)
    - [6. Install (The Magic Step)](#6-install-the-magic-step)
      - [For Option A (Standard):](#for-option-a-standard)
      - [For Option B (LUKS + TPM):](#for-option-b-luks--tpm)
    - [7. Finish](#7-finish)
  - [🎨 Phase 3: Post-Install Setup](#-phase-3-post-install-setup)
    - [1. Move Config to Home](#1-move-config-to-home)
    - [2. (Optional) Cleanup Unused Hosts](#2-optional-cleanup-unused-hosts)
  - [🛠️ Phase 4: Customization](#️-phase-4-customization)
    - [Setup (optional) `local-packages.nix`](#setup-optional-local-packagesnix)
    - [Setup (optional) `flatpak.nix`](#setup-optional-flatpaknix)
  - [🔄 Daily Usage \& Updates](#-daily-usage--updates)
  - [❓ Troubleshooting](#-troubleshooting)
    - [Error: `path '.../hardware-configuration.nix' does not exist`](#error-path-hardware-configurationnix-does-not-exist)
    - [Error: `home-manager: command not found`](#error-home-manager-command-not-found)
    - [Error: `permission denied` opening `flake.lock`](#error-permission-denied-opening-flakelock)
    - [Error: `returned non-zero exit status 4` during rebuild](#error-returned-non-zero-exit-status-4-during-rebuild)
    - [Weird keyboard layout during install](#weird-keyboard-layout-during-install)
    - [Caelestia/noctalia: some fonts issue](#caelestianoctalia-some-fonts-issue)
  - [❄️ Note on the declarative aspects](#️-note-on-the-declarative-aspects)
  - [📝 Project Origin and Customization](#-project-origin-and-customization)
  - [Showcase](#showcase)
    - [Hyprland with waybar](#hyprland-with-waybar)
    - [Hyprland with Caelestia/quickshell lockscreen](#hyprland-with-caelestiaquickshell-lockscreen)
    - [Hyprland with noctalia](#hyprland-with-noctalia)
    - [Hyprland with noctalia/quickshell lockscreen](#hyprland-with-noctaliaquickshell-lockscreen)
    - [KDE](#kde)
    - [Gnome](#gnome)
    - [XFCE](#xfce)
  - [Other resources](#other-resources)
    - [Structure](#structure)
    - [In-depth-files-expl](#in-depth-files-expl)
    - [Issues](#issues)
    - [Ideas](#ideas)
    - [Usage guide](#usage-guide)

## ✨ Features

### 🖥️ Adaptive Host Support:

Leverage `denix` to create a customized environments where it's possible to choose the modules to enable and configure their behaviour using `constants` which acts as variables passed to that file logic

- This allow to have a tailored experience right from the start,
- For reference look point ([5. Configure the host folder](#5-configure-the-hosts-folder)). TODO: change path to denix usage guide

#### Host-specific home-manager modules

Using the `/Users` folder it's possible to define modules separated from the system-wide one allowing to have highly opinionated and user/host specific modules separated


#### Host-specific general home-manager modules tweaks

- Allow to add/customize some feature of general home-manager modules (the one available for everyone)
  - For example a host may have different keyboard layouts. This feature allow to have in the waybar specific country flags without modifying the global waybar configuration

---


### ❄️ Hybrid (declarative + non declarative for some modules)

- Some modules are better customized using their official methods (aka not with nix-sintax).
- In this case a `.nix` file applies a basic logic and/or source an external directory/file; while other files/directories handles the rest.
  - For a more in-depth explanation see [❄️ Note on the declarative aspects](#️-note-on-the-declarative-aspects)

---

### 🎨 Theming

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

### 🖌️ Wallpaper(s)

Wallpapers are defined to be hosts specific and they are tied to the monitor list.

- They automatically apply smartly in all desktop environments except xfce

- The first monitor get the first wallpaper, the second monitor the second wallpaper etc.
  - In kde plasma the primary monitor override this settings. If nothing is done the behavior is as expected,
  - If the "primary" monitor is changed in the system settings than it will get the first wallpaper in teh list.

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

### niri-main.nix

Comment out or remove the specific lines that handles the wallpaper logic

```nix
  fetchedWallpapers = map (
    w:
    pkgs.fetchurl {
      url = w.wallpaperURL;
      sha256 = w.wallpaperSHA256;
    }
  ) constants.wallpapers;

  # 2. Generate 'swww' commands by zipping Monitors with Wallpapers
  wallpaperCommands = lib.imap0 (
    i: mon:
    let
      # Logic: Use wallpaper at index 'i'.
      # If we run out of wallpapers, fallback to the FIRST one (index 0).
      wp =
        if i < builtins.length fetchedWallpapers then
          builtins.elemAt fetchedWallpapers i
        else
          builtins.head fetchedWallpapers;
    in
    {
      command = [
        "swww"
        "img"
        "-o"
        mon
        "${wp}"
      ];
    }
  ) enabledMonitors;
```

```nix
++ wallpaperCommands
```

### cosmic-main.nix

Comment out or remove the specific lines that handles the wallpaper logic

```nix
let
  activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) constants.monitors;
  monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;

  wallpaperFiles = map (
    wp:
    "${pkgs.fetchurl {
      url = wp.wallpaperURL;
      sha256 = wp.wallpaperSHA256;
    }}"
  ) constants.wallpapers;

  # If there are more monitors than wallpapers, reuse the last wallpaper
  getWallpaper =
    index:
    if index < builtins.length wallpaperFiles then
      builtins.elemAt wallpaperFiles index
    else
      lib.last wallpaperFiles;

  monitorConfig = lib.concatStringsSep "\n" (
    lib.lists.imap0 (i: port: ''
      [output."${port}"]
      source = "Path"
      image = "${getWallpaper i}"
      filter_by_theme = false
    '') monitorPorts
  );
in
```

```nix
xdg.configFile."cosmic/com.system76.CosmicBackground/v1/all".text = ''
      ${monitorConfig}

      # Fallback for any monitor not explicitly named above
      [output."*"]
      source = "Path"
      image = "${builtins.head wallpaperFiles}"
      filter_by_theme = false
    '';
```

---

### 🪟 Multiple Desktop Environments

- **Hyprland**: A modern, tile-based window compositor setup on Wayland. You can choose between these options:
  - **Hyprland + waybar**
    - A regular hyprland setup with a waybar

  - **Hyprland + caelestia with quickshell**
    - Be careful with the choice of font. If a chosen font is not installed then there are conflicts
    - The json config is completely declarative. It can be modified in `caelestia-config.nix`
    - For the theming the shell only support the themes inside it's store. If the chosen base16 one is different then the shell will look different than the rest of the system.
      - **caelestia logout crash**
        - Note the official caelestia shell.json uses an aggressive terminate user, which does not work for uwsm
        - replace every of it to `"caelestia-logout` which is the name of the logout script in `caelestia-main.nix`

  - **Hyprland + noctalia with quickshell**
    - Noctalia include many configuration aspect so i choose to let the user manually change the config in the noctalia gui.
    - Be careful with the choice of font. If a chosen font is not installed then there are conflicts
  - Some aspects are defined declarative. See `noctalia-config.nix`
  - For the theming the shell only support the themes inside it's store. If the chosen base16 one is different then the shell will look different than the rest of the system.

- **niri + noctalia with quickshell**
  - Noctalia include many configuration aspect so i choose to let the user manually change the config in the noctalia gui.
  - Be careful with the choice of font. If a chosen font is not installed then there are conflicts
  - Some aspects are defined declarative. See `noctalia-config.nix`
  - For the theming the shell only support the themes inside it's store. If the chosen base16 one is different then the shell will look different than the rest of the system.

- **KDE Plasma**: A highly configurable desktop environment, with a launcher similar to windows
- **Gnome**: A famous and simple desktop environment, with a launcher similar to macOS. Ubuntu/mint user are very used to it
- **Cosmic**: A revisited gnome made from the company system76, known for being the creators of popOS
  - Cosmic as for now is highly unstable. Expect freezes, black screen while logging out, keybindings not working, etc etc
- **XFCE**: A lightweight, stable, and classic desktop experience.
  - For now xfce is enabled only if the `guest` user is enabled.

You can enable or disable desktop environments (Hyprland, GNOME, KDE, etc.) by editing `variables.nix`. However, disabling the environment you are currently using requires caution to avoid being locked out of the system.

> **⚠️ Warning:** If you set your **current** desktop to `false` and run `nixos-rebuild switch`, the graphical interface will terminate immediately. You will be dropped into a TTY, and in some cases, your user shell may break, forcing you to recover via `root`.

#### ✅ The Safe Way (Prevent Lockouts)

When changing Desktop Environments, **do not** apply the config immediately. Instead, build it for the _next_ boot. This ensures you can reboot cleanly into the new environment.

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

- **User:** `root`
- **Password:** (Same as your admin user, unless explicitly changed).

2. **Repair the System:**
   Run the following commands to rebuild the system from the root user. Replace `<your-user>` with your actual folder name (e.g., `krit`).

```bash
# 1. Enter the NixOS directory
cd /home/<your-user>/nixOS

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

### 👤 Ephemeral Guest User

A specialized secure account for visitors (basic features):

- **Login credentials**: both password and usernames are `guest`

- **Restricted**: No `sudo` access and no permission to view nor modify the NixOS configuration.

- **Essential Tools**: Pre-loaded with a Browser, File Manager, Text Editor, image viewer, archive manager, calculator.

- **Forced desktop environment**: This user only has access to `xfce` and its default applications. If the guest tries to acces a non-allowed de/wm then the pc reboots automatically.
- Applications that require sudo priviliges either do not open or simply fail to do anything.
- If you want the guest user to have access to all de then it is enough to remove all "rebooting" logic

- **Tailscale firewall**: This user does not have access to tailscale and can not ping even local ip regardless if tailscale is on or off

- **Privacy Focused**: The entire user home folder (including browser cookies, sessions, and saved files) is wiped automatically on every reboot or shutdown (logging out keep the data).
  - For now this is achieved by using `tmpfs`. This tells that the user data (home path) is written on ram and not ssd/hdd.
    - This has 3 major advantages:
      - Lifespan of the pc component (ram is rated to last more than disks)
      - Ensure privacy: Defining a script to delete the content in a disk is subject to silent fails. This means the data could not be completely removed. Ram is sure to be deleted once the pc restart
    - The main disadvantage is a possible performance issues on system with low ram.
      - The current config tells that the guest user can use up to a certain ram space. If a host has low ram it is possible to have freezes

- It is possible to change the of the data deletion from ram to disk by changing `guest.nix`

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

### 🏠 Home Manager Integration

Fully declarative management of user dotfiles and applications.

### 🧇 Tmux

Customized terminal multiplexer.

### 🌟 Multiple shells + Starship

Starship provide beautiful git status symbols, programming language symbols, the time, colors and many other features.

- You can choose for each host between these user shell at any time:
  - bash
  - zsh
  - fish

### 🦺 Optional BTRFS snapshots

- Possibility to enable snapshots and define an host-specific retention policy
- These are only possible if the filesystem is `btrfs`
- Nor the filesystem nor the snapshots modules are mandatory. If you opt for any filesystem different than `btrfs` you can simply keep the variable to false, or remove it and also remove `~/nixOS/nixos/modules/snapshots.nix`
- The `template-host` contains a file named `disko-config` which can be used to configure btrfs automatically.
  - If you prefer to not use `disko` then you should remove that file from the template-host and configure `btrfs` manually using the nix installer

### ❔ SOPS-nix support

- Sops is already enabled in `flake.nix` and `.sops.yaml` contains the necessary code to add the host-specific keys
- For an host to use sops it must be added to the host-specific configuration.nix, otherwise it is ignored. An example is the following:

```nix
# If you want to have the convenience of the aliases then the name must match the format here
sops.defaultSopsFile = ./optional/host-sops-nix/<hostname>-secrets-sops.yaml;
sops.defaultSopsFormat = "yaml";
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
```

The format for the common secrets (also according to the aliases) should be `<user>-common-secrets-sops.yaml`

If you intend to use the hostname `nixos-desktop` you should remove the entire content of the existing one, as it contains my own personal configurations and change and create the new host public key. Basically after a new rebuild and a `nixos-desktop` which contains the bare minimum from `template-host` you would run:

```bash
# Get the new host public key
nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"

# Then update the user with the admin public key and the host public key

# Then invite the host
sops updatekeys hosts/nixos-desktop/optional/host-sops-nix/<hostname>-secrets-sops.yaml
```

---

### 📦 Cachix support

- It's a tool that allow to build the system much faster.
  - The binaries needed to build this system are located on [cachix](https://app.cachix.org/)
    - Assuming you have a good internet the build is much faster and does not rely on the host hardware.

---

### 🧑‍🍳 Denix support
- Leverange [denix](https://github.com/yunfachi/denix) to provide a simple way to add, remove, enable/disable modules and their options

---
### 🖥️ Multi-architecture support

- It uses smart conditionals to allow support for multiple architectures
  - `aarch64-linux`
  - `x86_64-linux`
- Currently the limitation for `aarch64-linux` are the following:
  - `gpu-screen-recorder`:
    - It's used both by `caelestia` and `noctalia`. The shells can be installed and used in both architecture but the screen recording features will not work on `aarch64-linux`

---

# 🚀 NixOS Installation Guide

## 📦 Phase 1: Preparation

### 1. Download & Flash

1. **Download:** Get the **NixOS Minimal ISO** (64-bit Intel/AMD) from [nixos.org](https://nixos.org/download.html).
2. **Flash:** Use **Rufus,balena etcher or similar** to write the ISO to a USB stick.

- **Partition Scheme:** GPT
- **Target System:** UEFI (non-CSM)

3. **BIOS:** Ensure **Secure Boot** is Disabled and your BIOS is set to **UEFI** mode.

### 2. Boot & Connect

1. Insert the USB and boot your computer.
2. Select **"UEFI: [Your USB Name]"** from the boot menu.
3. Once the text console loads (`[nixos@nixos:~]$`):

- **WiFi:** Run `sudo nmtui`, select "Activate a connection", and pick your network.
- **Ethernet:** Should work automatically. verify with `ping google.com`.

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
lsblk -o NAME,SIZE,FSAVAIL
```

* Look for your main disk (e.g., `476G` or `931G`).


* Note the name: usually **`nvme0n1`** (for SSDs) or **`sda`**.



### 3. Create Your Host and import the chosen disko-config

Copy the template to a new folder for your machine. Replace `my-computer` with your desired hostname.
You may choose between copying the `minimal` or the `full` template host

```bash
cd hosts
cp -r template-host-full my-computer
cd my-computer
```

Edit the host `default.nix` and add in the `nixos` block the import for the chosen disko-config. Remember to only have one of the 2 imported
```nix
  nixos =
    { ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "25.11";
      imports = [
        inputs.catppuccin.nixosModules.catppuccin
        #inputs.nix-sops.nixosModules.sops # Tough an import does not cause the build to fail it's removed for lightness. Enable if used
        inputs.niri.nixosModules.niri

        ./hardware-configuration.nix
        
        ./disko-config-btrfs
        ./disko-config-btrfs-luks-impermanence
      ];
```

### 4. Configure the Drive

Choose **ONE** of the following methods depending on whether you want encryption.
- Both disko-config are under ~/nixOS/hosts/template-host-full

#### Option A: Standard (No Encryption)

1. Open the standard config: `nano disko-config-btrfs.nix`.
2. Find the line: `device = "/dev/nvme0n1";` and change it to your actual drive name from step 2.
3. **Save**: `Ctrl+O` -> `Enter` -> `Ctrl+X`.

#### Option B: Secure (LUKS + TPM 2.0)

1. Open the encrypted config: `nano disko-config-btrfs-luks-impermanence.nix`.


2. Find the linse: `device = "/dev/nvme0n1";` and `nvme0n1 = {` and change them to your actual drive name from step 2.


3. **Save**: `Ctrl+O` -> `Enter` -> `Ctrl+X`.

### 5a. Configure Critical Variables

We only need to set the basics now. You can customize themes and wallpapers later in the GUI.

```bash
nano default.nix
```

* **`user`**: Change `"template-user"` to your real user.
* **⚠️ CRITICAL**: Do not install as `template-user` and try to rename it later. Set your real user **NOW**.
* **`homeManagerSystem`**: The template is `x86_64-linux`. If you have a newer ARM-based PC then `aarch64-linux`.
* **Keyboard**: Set `keyboardLayout` (e.g., `"us,it"`) and `keyboardVariant` (e.g., `"intl,,"`) to have an easier time to login and user  the terminal right from teh beginning

### 5b. Enable suggested modules

Check the documentation [denix starting documentation](#-denix-support). To find a descriptions of possible modules that are available and check `template-host-full-default.nix` for suggested modules (one that have a `enable = true;` block)

---

### 6. Install (The Magic Step)

Run the commands corresponding to the configuration you chose in Step 4.

#### For Option A (Standard):

```bash
# 1. Partition & Mount (Wipes the drive!)
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode format ~/nixOS/hosts/my-computer/disko-config-btrfs.nix

# 2. Generate Hardware Config
nixos-generate-config --no-filesystems --root /mnt --dir /etc/nixos/hosts/my-computer

# 3. Mount
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode format ~/nixOS/hosts/my-computer/disko-config-btrfs.nix

# 4. Install
cd /etc/nixos

sudo nixos-install --flake .#my-computer
```

#### For Option B (LUKS + TPM):

```bash
# 1. Partition & Mount (Wipes the drive!)
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode format ~/nixOS/hosts/my-computer/disko-config-btrfs-luks-impermanence.nix

# 2. Generate Hardware Config
nixos-generate-config --no-filesystems --root /mnt --dir /etc/nixos/hosts/my-computer

# 3. Mount
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode format ~/nixOS/hosts/my-computer/disko-config-btrfs-luks-impermanence.nix

# 4. Install
cd /etc/nixos

sudo nixos-install --flake .#my-computer
```

### 7. Finish

1. Set your **root password** when prompted.
2. Type `reboot` and remove the USB stick.
3. **(LUKS Only)**: Once you boot into your new system, bind the TPM for auto-unlock:

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

- This command can be run to re-bind if needed (such as after a motherboard change)
---

## 🎨 Phase 3: Post-Install Setup

Congratulations! You are now logged into your new NixOS desktop.

- After installing the cosmic de setup dialog (if you enabled it) can appear (if you enabled cosmic) even if not inside cosmic itself. Either configure it regardless of which de you are on or close it. This is only a one time thing

### 1. Move Config to Home

Your configuration is currently owned by `root` in a system folder. Let's move it to your home folder so you can edit it safely.

1. Open your terminal.
2. Move the config:

```bash
sudo mv /etc/nixos ~/nixOS
sudo chown -R $USER:users ~/nixOS
```

### 2. (Optional) Cleanup Unused Hosts

Now that you have your own host (`hostname`), you might want to delete the other hosts, such as `template-host`

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

_Example input: `my-computer` (This will delete every host except this one)._

---

## 🛠️ Phase 4: Customization


### Setup (optional) `local-packages.nix`

- It contains packages that are intended to only be installed in that specific hosts
  - add as needed

### Setup (optional) `flatpak.nix`

- It contains flatpak packages that are intended to only be installed in that specific hosts
  - add as needed




---

## 🔄 Daily Usage & Updates

Whenever you edit a file, use these aliases to apply your changes. You don't need to type the long `nixos-rebuild` command.

The normal switch command handle both a system and a home-manager rebuild.

| Alias     | Command                 | Description                                                            |
| --------- | ----------------------- | ---------------------------------------------------------------------- | --- |
| **`sw`**  | `nh os switch`          | **System Rebuild**. Rebuild everything                                 |     |
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
# This smart command automatically fetch the user so no changes are needed
sudo chown -R $USER:users ~/nixOS
```

### Error: `returned non-zero exit status 4` during rebuild

**Cause:** Common during massive updates. System built fine but failed to restart a service (often DBus).

- Some time the rebuild seems stuck.
  - Tough it may also be a true stuck chanches are that the system correctly builded but can not show this in the cli

### Weird keyboard layout during install

This is a problem that i encountered. It may have been user error but i write it here just to be safe.

Even tough i selected us international during the gui installer once rebooted into cli (since i selected no desktop) i was greeted with all mixed keys. Meaning what i saw on the physical keyboard were not the keys that were pressed.

- For me the layout that nixOS had at that moment in time was `dvorak`
- This is solvable by manually converting the keyboards or just ask an ai what keys to press on a dvorak layout to actually input what the user wants. After the user login is successful input the following command `loadkeys <layout>` (until this command run successfully the keyboard layout is still `dvorak`). After this the problem should be solved and since the layout are chosen declarative this should not be a problem anymore

### Caelestia/noctalia: some fonts issue

- This is mainly caused if the font you are trying to use is not installed. You can install them, either hosts-specific (better in `configuration.nix`) or in `home-packages.nix`

## ❄️ Note on the declarative aspects

Some modules are better customized using their official methods.

These modules uses a dedicated `*.nix` file where it defines that the main configuration is taken from another place and unified with the respective `*.nix` file

These blocks are configured in such a way that allow 2 scenario:

1: The user has a customized setup (either with stowing from another github repo) or directly in the original intended location.

- In this case there is an hybrid environment. Meaning everything defined in both `*.nix` files and the original file/directory apply

2: The user does not have a customized setup the original location is either empty or default (after installing the program)

- In this case the behaviour in `*.nix` apply but since the rest is default it is like not applying it at all

Currently this behaviour happens here:

- **shells**:
  - Nix reference: `zsh.nix`, `bash.nix` `fish.nix`
  - Original reference: `~/.zshrc_custom`, `.bashrc_custom`, `.custom.fish`

- **caelestia/noctalia**:
  - Nix reference: `caelestia-main.nix`, `noctalia-main.nix`
  - Original reference: `~/.config/caelestia/shell.json`, `~/.config/noctalia/config.json`

## 📝 Project Origin and Customization

This NixOS configuration project began as local copy and adaptation of the excellent work by **Andrey0189** from their repository: [https://github.com/Andrey0189/nixos-config-reborn](https://github.com/Andrey0189/nixos-config-reborn).

I would like to extend my thanks to **Andrey0189** for providing a robust starting point.

While the original repository laid the foundation, this setup has been **heavily customized** and expanded over time to suit my personal needs and workflows. Key changes include:

- **Heavily improved hosts variables**: Modified the hosts directory such that it contains many more aspects that can differs from host to host
- **Multiple Desktop Environments**: Added configuration and support for multiple desktop environments
- **Ephemeral Guest User**: Implemented a secure, non-persistent guest account with automatic home directory wiping on reboot.
- **Theming Overhaul**: Integrated a base 16 colorscheme selection alongside Catppuccin official theming via `stylix`.
- **Hybrid Declarative Aspects**: Detailed and implemented a hybrid approach for tools like Neovim and Zsh, allowing for declarative configuration while respecting and integrating official, non-declarative customization methods.
- **Flake Configuration**: Enhanced the `flake.nix` file to suit the logic that there are many more variables that differs from hosts to hosts
- **Common modules**: Allow the user to have general home-manager modules for certain hosts
- **Cachix support**: Enhanced the `flake.nix` file to suit the logic that there are many more variables that differs from hosts to hosts
- **Multi-architecture support**: Support for both x86 and aarch pc

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

### Hyprland with waybar

![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-showcase.png)

### Hyprland with Caelestia/quickshell lockscreen

![hyprland-caelestia](./Documentation/showcase-screenshots/quickshell-lockscreen.png)

### Hyprland with noctalia

![hyprland-caelestia](./Documentation/showcase-screenshots/noctalia_custom-neovim.png)

### Hyprland with noctalia/quickshell lockscreen

![hyprland-caelestia](./Documentation/showcase-screenshots/noctalia-screen_locker.png)

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

### [Usage guide](./Documentation/usage/)

This folder contains a guide on how basic aspects should be implemented, such as:

- Creating a system-wide module
- Create a general home-manager modules that apply to all hosts
- Create a host-specific home-manager modules
- Theming guide

It also contains some other guides such as

- sops
- tmux
- cachix
