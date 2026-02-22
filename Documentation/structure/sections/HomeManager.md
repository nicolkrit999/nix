- [🏠 Home Manager (`home-manager/`)](#-home-manager-home-manager)
  - [`home.nix`](#homenix)
    - [`hyprland-hyprpaper.nix`](#hyprland-hyprpapernix)
    - [`hyprland-main.nix`](#hyprland-mainnix)
  - [🪟 Niri Sub-modules (`home-manager/modules/de-wm/niri/`)](#-niri-sub-modules-home-managermodulesde-wmniri)
    - [`niri-binds.nix`](#niri-bindsnix)
    - [`niri-main.nix`](#niri-mainnix)
  - [🪟 KDE Plasma Sub-modules (`home-manager/modules/de-wm/kde/`)](#-kde-plasma-sub-modules-home-managermodulesde-wmkde)
    - [`default.nix`](#defaultnix)
    - [`kde-desktop.nix`](#kde-desktopnix)
    - [`kde-files.nix`](#kde-filesnix)
    - [`kde-input.nix`](#kde-inputnix)
    - [`kde-krunner.nix`](#kde-krunnernix)
    - [`kde-kscreenlocker.nix`](#kde-kscreenlockernix)
    - [`kde-main.nix`](#kde-mainnix)
    - [`kde-panels.nix`](#kde-panelsnix)
    - [`kde-binds.nix`](#kde-bindsnix)
  - [📊 Waybar Sub-modules (`home-manager/modules/cli-programs/waybar/`)](#-waybar-sub-modules-home-managermodulescli-programswaybar)
    - [`default.nix`](#defaultnix-1)
    - [`style.css`](#stylecss)

# 🏠 Home Manager (`home-manager/`)

These configurations define your personal environment. Changes here do not require root access as they only affect the current user.

- When modifying something here it is usually enough to run `hms` to rebuild

## `home.nix`

The main entry point for Home Manager. It imports the modules folder and the packages list. It defines user identity (username, home directory) and state version.

- It include a script `removeExistingConfigs` which fix the clobbered error for certain files
  - Files or directories that cause these kind of error can be added here.
  - A more graceful solution is to add in this file the backup block. I did not opted for this solution because i do not want to have to cleanup useless backups from time to time.
  ```

## `home-packages.nix`

A simple list of user-space packages (like neovim, Discord, btop) that are installed only for your user (but for all hosts), keeping the system root clean.

- It contains packages divided into 2 sectiosn:
  - Applications to keep: These are packages that are either referenced somewhere explicitely or that I personally need in a home-manager level
  - Other application: These are packages that i find useful for my specific uses. These can be freely removed/moved

## 📂 General modules

### `bat.nix`

Configuration for `bat` (a modern `cat` clone).

- **Theming:** Uses the base16 themes or catppuccin official nix repo based on the user choice in `variables.nix`

### `core.nix`

The "Hub". It imports every single other file in this directory.

- If a new module is created, it _must_ be added here for Home Manager to see it.
- To disable a certain module commenting it here is another way for disabling it
- Desktop environment should not be added here because they are automatically enabled/disabled depending on the user choices in `variables.nix`

### `eza.nix`

Configuration for `eza` (a modern `ls` clone).

- **Theming:** Uses the base16 themes or catppuccin official nix repo based on the user choice in `variables.nix`

### `git.nix`

Git version control settings.

- **User-identity:** It takes the github username and e-mail from `variables.nix` (hosts-specific)

### `lazygit.nix`

Configuration for the terminal UI for Git.

- **Theming:** Uses the base16 themes or catppuccin official nix repo based on the user choice in `variables.nix`

### `mime.nix`

It setup the default application for some file based on `variables.nix`

### `neovim.nix`

Wrapper for the Neovim text editor.

- **Note:** This module only defines a few nix-specific behaviour. The remaining of the config is taken from the regular `~/.config/nvim` folder
- Since neovim is highly customizable it is better to let lua files handle the main configuration
- Stylix is explicitly disabled here to allow for complex, manual Lua-based theming.

### `qt.nix`

Configures the appearance of **Qt (Qt5 & Qt6)** applications. Respect whatever catppuccin is enabled and the Light/Dark mode preference (`polarity`).

- Unless heavy changes are made this file should not be styled by `stylix.nix`, doing so causes the kde plasma session to crash

### `starship.nix`

Shell prompt configuration.

- **Theming:** Uses the base16 themes or catppuccin official nix repo based on the user choice in `variables.nix`
- **Features** It configures the prompt to show specific symbols for SSH sessions, Git status, and errors.

### `stylix.nix`

The central theming engine for the system.

- **Theming:** Acts as a "switch" between two modes based on the user's choice in `variables.nix`:
  - **Stylix Mode (`catppuccin = false`):** Automatically generates themes for GTK, Wallpapers, and apps using a specific **Base16 scheme** (e.g., `gruvbox`, `dracula`)
  - **Catppuccin Mode (`catppuccin = true`):** Disables Stylix's automation for specific apps (like GTK, Alacritty, Hyprland) and manually injects the official **Catppuccin** theme with the user's chosen flavor and accent
    - if `catppuccin` is true then stylix targets should be disabled. This means `*.enable = !catppuccin`

- **Features:**
  - **Conditional Logic:** Uses `lib.mkIf` to dynamically enable or disable Stylix targets to prevent conflicts with manual theme modules.
  -
  - **GTK Overrides:** Manually forces GTK themes and icons when Catppuccin mode is active to ensure deep system integration
  -
  - **Font Management:** Installs and configures a comprehensive suite of fonts (JetBrains Mono, Noto, FontAwesome) for consistent typography across the OS
  -
  - **Dark/Light Mode:** Forces the system-wide "prefer-dark" or "prefer-light" signal via `dconf` to ensure GTK4 apps respect the global polarity

### `tmux.nix`

Terminal multiplexer configuration. Includes behaviour and keybindings

- **Theming:** Uses the base16 themes or catppuccin official nix repo based on the user choice in `variables.nix`
-
- **Features:**
  - **Navigation:** Configures a `keybindings + Arrow keys` to switch panes and a `keybindings + Number keys` to switch windows instantly
  -
  - **Workflow Shortcuts:** Includes custom bindings to launch specific workspaces like the system configuration or notes directly in Neovim
  - **Window Management:** Sets custom split bindings and resizing shortcuts (`Alt+Shift+Arrows`) for rapid layout control
  - **Vim Mode:** Enables standard Vim keybindings for efficient scrolling and copy-paste operations



### `walker.nix.nix`

This file configures walker, the application launcher and menu utility for Wayland. It defines the window geometry, behavior, and appearance logic.

- **General Idea:** It serves as the "Start Menu" and a generic selection tool for scripts (like clipboard managers).

- **Theming:** Uses the base 16 theme

### `zsh.nix`

Shell configuration.

- **Function:** Adds Nix-specific aliases (like `hms` for Home Manager Switch) and integrates with an existing `~/.zshrc_custom` file
  - This allow an hybrid setup where one can configure `~/.zshrc_custom` to be valid regardless of os, basically using globally valid aliases and options

## 🪟 Caelestia & noctalia (`home-manager/modules/de-wm/.../`)

### `caelestia-main.nix` and `noctalia-main.nix`

- There is nothing special here since it allow a complete setup using the official .json file
- The only thing these files do is making sure the hyprland signature is valid and run some scripts to make the shell work

## 🪟 Cosmic Sub-modules (`home-manager/modules/de-wm/cosmic/`)

### `cosmic-main.nix`

This file handles the visual configuration of the cosmic session, including wallpapers, themes, and interface tweaks.

### `default.nix`

This is the module entry point for the cosmic configuration folder. It uses the `imports` list to aggregate the separate configuration files into a single module.

- **General Idea:** It serves as an index, telling Home Manager which files are part of the cosmic setup.
- **Effect of Changing:** Adding or removing a file path here determines whether that specific configuration file is loaded or ignored by the system. If a file exists but is not listed here, its settings will not be applied.

### `cosmic-binds.nix`

This file manages custom keyboard shortcuts for cosmic.

## 🪟 GNOME Home Manager Sub-modules (`home-manager/modules/de-wm/gnome/`)

### `default.nix`

This is the module entry point for the GNOME configuration folder. It uses the `imports` list to aggregate the separate configuration files into a single module.

- **General Idea:** It serves as an index, telling Home Manager which files are part of the GNOME setup.
- **Effect of Changing:** Adding or removing a file path here determines whether that specific configuration file is loaded or ignored by the system. If a file exists but is not listed here, its settings will not be applied.

### `gnome-main.nix`

This file handles the visual configuration of the GNOME session, including wallpapers, themes, and interface tweaks.

- **Wallpaper:** As far as i know gnome does not allow to use nix os to define different wallpapers based on different monitor. A tool called `hydrapaper` should allow to do so. It is installed as a package in case it is needed
- **Theming Logic:**
  - **Icons:** It intelligently selects between `Papirus-Dark` or `Papirus-Light` based on the global `polarity` variable defined in `variables.nix`.
  - **Catppuccin:** If Catppuccin is enabled, it installs the necessary GTK theme packages but allows the global **Stylix** module to handle the actual application of the GTK theme string (to prevent conflicts). It manually enforces the icon theme to ensure consistency.

- **Interface Tweaks:** It restores the **Minimize and Maximize buttons** to the window title bars, which are hidden by default in standard GNOME.

### `gnome-binds.nix`

This file manages custom keyboard shortcuts for GNOME. Since GNOME does not use a simple config file for keys, this module programmatically generates `dconf` entries to register custom actions.

## 🪟 Hyprland Sub-modules (`home-manager/modules/de-wm/hyprland/`)

### `hyprland-binds.nix`

This file defines the keybindings for Hyprland. It assigns specific keyboard combinations and mouse actions to system commands, such as launching applications (terminal, browser, menu), managing windows (move, resize, close, floating), and controlling hardware (volume, brightness).

### `default.nix`

This is the module entry point for the Hyprland configuration folder. It uses the `imports` list to aggregate all the separate configuration files (like `gnome-binds.nix`, `gome-main.nix`, etc.) into a single module.

- **General Idea:** It serves as a index, telling Home Manager which files are part of the Hyprland setup.
- **Effect of Changing:** Adding or removing a file path here determines whether that specific configuration file is loaded or ignored by the system. If a file exists but is not listed here, its settings will not be applied.

### `hyprland-hypridle.nix`

This file configures the system's idle behavior using the `hypridle` daemon. It defines a series of timeouts that trigger specific power-management actions when the computer is left inactive, such as dimming the screen, locking the session, turning off monitors, and finally suspending the system. It includes fallback logic to use default values if specific host configurations are missing.

The variables are hosts-specific, so they are defined and changed in `variables.nix`. It include a fallback logic

### `hyprland-hyprlock.nix`

This file configures the visual appearance and behavior of the lock screen using `hyprlock`. It defines the background (using screenshots with blur effects), the password input field, and general settings like the grace period before a password is required. It integrates with the `catppuccin` module for theming but allows for manual overrides.

- **Personalization:** If catppuccin is disabled then configuring a custom clock and input field appearance is necessary. Below there is an example

```nix
# Clock
label = {
          text = "cmd[updates:1000] date +'%I:%M %p'";
          font_size = 96;
          font_family = "JetBrains Mono";
          position = "0, 600";
          halign = "center";
          walign = "center";
          shadow_passes = 1;
        };
```

```nix
# Password input
input-field = [
  {
    size = "200, 50";
    position = "0, 0"; # Center. Use "-" for above
    monitor = "DP-1"; # Visible only on monitor "DP-1". Use "" for all
    dots_center = true;
    font_color = "rgb(${config.lib.stylix.colors.base05})"; # Foreground color from Stylix theme
    inner_color = "rgb(${config.lib.stylix.colors.base00})"; # Background color from Stylix theme
    outer_color = "rgb(${config.lib.stylix.colors.base0D})"; # Blue from Stylix theme
    outline_thickness = 5;
    placeholder_text = "Welcome back";
    shadow_passes = 1;
  }
];
```

### `hyprland-hyprpaper.nix`

Set wallpapers using `hyprpaper` and assigns them to specific monitor ports (eg. DP-1). It does not apply a wallpaper to a disabled monitor. The wallpapers are defined in a list, allowing as many wallpapers as needed. They are applied from top to bottom in the same order as the `monitors` block. So first wallpaper goes to first monitor in the list

The wallpapers are hosts-specific, so they are defined and changed in `variables.nix`. It include a fallback logic.

- **Fallback logic:** It handles 2 cases (in the `get.Wallpaper` function):
  - More wallpapers than monitors: Since it goes from top to bottom once all monitors are covered the remaining wallpapers are ignored
  - Less wallpapers than monitors: All remaining monitors get the last wallpaper in the list

### `hyprland-main.nix`

This is the core configuration file for Hyprland. It handles the fundamental setup including monitor fallback, environment variables (for Wayland support), startup applications (like bars and clipboards), window rules (where apps open and how they look), and the visual style (borders, gaps, animations) and the default screenshots folder (taken using the keybindings).

- **Screenshot folders:** To make sure the directory exist in a declarative way this path needs to match the path defined in `../../home.nix`, function `createScreenshotsDir`

## 🪟 Niri Sub-modules (`home-manager/modules/de-wm/niri/`)

### `niri-binds.nix`

This file defines the keybindings for Niri. It assigns specific keyboard combinations to system commands, relying heavily on the `vars` system to remain application-agnostic. It handles application launching (terminal, browser, file manager), system utilities (screenshots, clipboard history, emoji picker), and window management (closing windows, toggling floating mode).

- **Launcher Logic:** It includes conditional logic to switch between the standard `walker` launcher and the custom `noctalia` launcher depending on your `variables.nix` configuration.
- **Screenshots:** It defines custom scripts for taking screenshots (fullscreen or area selection) using `grim` and `slurp`, automatically saving them to the Pictures folder and copying them to the clipboard.

### `niri-main.nix`

This is the core configuration file for the Niri compositor. It controls the visual appearance, input devices, display layout, and startup behavior. It integrates deeply with **Stylix** to ensure the window borders and shadows match the system-wide color scheme.

- **Monitor Management:** It contains complex logic to parse the `myconfig.constants.monitors` list. It automatically identifies monitors marked as "disabled" in your variables and generates the corresponding Niri commands to turn them off, while configuring the resolution and scale for enabled ones.
- **Startup & Environment:** It manages the autostart of essential background services (like `xwayland-satellite`, `polkit-gnome`, and `swww-daemon`) and sets necessary environment variables for Wayland compatibility.
- **Input & Layout:** It configures keyboard repeat rates, touchpad gestures (tap-to-click), and window layout settings (gaps, column widths, and focus rings).

## 🪟 KDE Plasma Sub-modules (`home-manager/modules/de-wm/kde/`)

These modules are generally configured using `plasma-manager` from the nix-community

### `default.nix`

This is the module entry point for the KDE configuration folder. It uses the `imports` list to aggregate all the separate configuration files (like `kde-main.nix`, `kde-desktop.nix`, etc.) into a single module.

- **General Idea:** It serves as an index, telling Home Manager which files are part of the KDE Plasma setup.
- **Effect of Changing:** Adding or removing a file path here determines whether that specific configuration file is loaded or ignored by the system. If a file exists but is not listed here, its settings will not be applied.

### `kde-desktop.nix`

This file configures the behavior and appearance of the desktop surface itself (the background area behind windows). It manages desktop icons, mouse interactions (right-click/middle-click behaviors), and desktop widgets.

- **General Idea:** It controls how you interact with the empty desktop space and how files/folders are displayed on it.

### `kde-files.nix`

This file handles low-level configuration by writing directly to specific KDE config files (like `spectaclerc` or `kdeglobals`). It is used for settings that the high-level `plasma-manager` modules might not support directly or where manual overrides are necessary.

- **General Idea:** It acts as a direct interface to KDE's configuration files, bypassing the abstraction layer for specific keys.

### `kde-input.nix`

This file manages the configuration for hardware input devices, including keyboards, mice, and touchpads. It allows for defining keyboard layouts, mouse acceleration profiles, and touchpad gestures.

- **General Idea:** It ensures your physical peripherals behave correctly, applying specific driver settings (Libinput) based on hardware IDs or generic definitions.

### `kde-krunner.nix`

This file configures KRunner, KDE's built-in launcher and search utility. It defines its position on the screen, activation behavior, and history settings.

- **General Idea:** It customizes the behavior of the "Run Command" interface

### `kde-kscreenlocker.nix`

This file controls the behavior and appearance of the screen locker. It integrates with system idle timers to determine when the screen should auto-lock and defines the visual theme of the lock screen.

- **General Idea:** It secures the session when idle and ensures the lock screen aesthetics match the rest of the system (e.g., wallpapers).

### `kde-main.nix`

This file handles the core workspace configuration and global theming logic for the KDE Plasma environment. It acts as the primary enabler for the Plasma module and manages visual elements like wallpapers, cursors, and the overall look-and-feel (e.g., Catppuccin vs. Breeze).

- **General Idea:** It serves as the "Theme Engine" and "Root" of the KDE setup, dynamically applying themes based on global system variables (like polarity or specific flavor preferences).

### `kde-panels.nix`

This file defines the configuration for Plasma panels (taskbar). It controls the dimensions, positioning, behavior (auto-hide), and the widgets contained within them (like the application launcher, task manager, and system tray).

- **General Idea:** It builds the layout of your desktop interface bars, determining where your open apps and system indicators live.

### `kde-binds.nix`

This file centralizes keyboard shortcuts and global hotkeys. It manages bindings for launching applications (like walker), system actions (like Spectacle screenshots), and window manager overrides.

- After doing changes to a previous config that did not work (basically when building some set of shortcuts, but after a log in/log out they do not work), once the code is fixed it is necessary to remove `~/.config/kglobalshortcutsrc` and then build, then log in/log out
  - This is because if certain shortcuts config are stuck then the only way to apply the new logic is to first remove the file that contains the broken state and then rebuild

* **General Idea:** It acts as the "Keybinding Manager," mapping specific key combinations to system commands or DBus actions.

## 📊 Waybar Sub-modules (`home-manager/modules/cli-programs/waybar/`)

### `default.nix`

This file configures Waybar, a status bar. It defines the bar's position, dimensions, module layout (left, center, right), and the specific behavior for each widget.

- **General Idea:** It acts as the "Dashboard" for your desktop, showing vital system information like workspaces, active window title, volume, battery status, and time.

- **Theming:** It is themed using the official Catppuccin Nix module or a Base16 theme, depending on user preference, with custom CSS styles applied via the `style` option.

- **Key Modules:**
  - **Workspaces:** Shows active and special workspaces, with dynamic icons.
  - **Window:** Displays the title of the currently focused window.
  - **Language:** Indicates the current keyboard layout with flags.
  - **Weather:** Fetches live weather data for a configured location using `wttr.in`.
  - **System Status:** Includes PulseAudio volume, Battery level, Clock, and System Tray.

### `style.css`

Intelligently define colors based on whatever catppuccin is enabled on the hosts or not
