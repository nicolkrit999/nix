# Hyprlock, SDDM & Terminal Constants Session (2026-03-27)

## Overview of All Changes

This session involved:
1. Enhanced hyprlock with time/date/username/password UI using base16 colors
2. SDDM pixie theme accent color from base16
3. Terminal constants restructure (string → attrset with cursor/animation options)
4. Bug fixes for files using old terminal constant format

---

## 1. Terminal Constants System (NEW STRUCTURE)

### Constants Definition Files

**NixOS:** `/home/krit/nix/modules/nixos/config/constants-nixos.nix` (lines 52-57)
**Darwin:** `/home/krit/nix/modules/darwin/config/constants-darwin.nix` (lines 19-24)

**Old format (DEPRECATED):**
```nix
terminal = strOption "alacritty";
```

**New format (CURRENT):**
```nix
terminal = {
  name = strOption "alacritty";       # Terminal emulator app name
  cursorStyle = strOption "block";    # block, beam, underline
  cursorBlink = boolOption false;     # Enable cursor blinking
  animation = boolOption false;       # Enable transient prompt animation on command execution
};
```

### Where Terminal Constants Are Used

| File | What It Uses | How |
|------|--------------|-----|
| `users/krit/common/programs/terminal-emulators/kitty.nix` | `cursorStyle`, `cursorBlink` | Lines 42-43: `cursor_shape`, `cursor_blink_interval` |
| `users/krit/common/programs/terminal-emulators/alacritty.nix` | `cursorStyle`, `cursorBlink` | Lines 29-33: `cursor.style.shape`, `cursor.style.blinking` |
| `modules/common/programs/shells/starship.nix` | `animation` | Line 36: `enableTransience` |
| `modules/nixos/toplevel/env.nix` | `terminal.name` | Line 9: `safeTerm` |
| `modules/nixos/toplevel/mime.nix` | `terminal.name` | Line 18: `safeTerm` |
| `modules/nixos/toplevel/home-packages-nixos.nix` | `terminal.name` | Line 40: `termName` |
| `modules/nixos/programs/de-wm/hyprland/hyprland-main.nix` | `terminal.name` | Line 25: `term` |
| `modules/nixos/programs/de-wm/niri/niri-binds.nix` | `terminal.name` | Lines 26, 54 |
| `modules/nixos/programs/de-wm/kde/kde-binds.nix` | `terminal.name` | Lines 88, 94, 108 |
| `modules/nixos/programs/de-wm/gnome/gnome-binds.nix` | `terminal.name` | Lines 27, 47, 64 |
| `users/krit/common/programs/file-managers/ranger.nix` | `terminal.name` | Lines 59, 70, 134 |
| `users/krit/common/programs/file-managers/yazi/yazi.nix` | `terminal.name` | Lines 121, 132, 440-441 |
| `users/krit/common/programs/cli-programs/neovim.nix` | `terminal.name` | Lines 24-25 |

### Host Configuration Examples

**nixos-desktop** (`hosts/nixos-desktop/default.nix` lines 136-141):
```nix
terminal = {
  name = myTerminal;      # "kitty"
  cursorStyle = "block";
  cursorBlink = false;
  animation = true;       # Enables starship transient prompt
};
```

**Krits-MacBook-Pro** (`hosts/Krits-MacBook-Pro/default.nix` line 19):
```nix
terminal.name = "kitty";  # Other options use defaults
```

**nixos-laptop** (`hosts/nixos-laptop/default.nix` line 89):
```nix
terminal.name = myTerminal;  # Other options use defaults
```

### Cursor Style Values

| Value | Kitty | Alacritty |
|-------|-------|-----------|
| `"block"` | `cursor_shape = "block"` | `shape = "Block"` |
| `"beam"` | `cursor_shape = "beam"` | `shape = "Beam"` |
| `"underline"` | `cursor_shape = "underline"` | `shape = "Underline"` |

### Animation (Transient Prompt)

When `terminal.animation = true`:
- Starship's `enableTransience` is set to `true`
- After command execution, the prompt collapses to a minimal form
- Only works with fish shell (starship limitation)

---

## 2. Hyprlock Enhancement with Base16 Theming

**File:** `/home/krit/nix/modules/nixos/services/hypr/hyprlock.nix`

### Module Arguments Changed

Line 1: Added `config` to access stylix colors
```nix
{ delib, lib, config, ... }:
```

### Color Accessors (inside `home.always` let block, lines 21-22)

```nix
c = config.lib.stylix.colors;              # For rgba() - returns hex without #
ch = config.lib.stylix.colors.withHashtag; # For direct use - returns #xxxxxx
```

### Wallpaper Fallback Logic (lines 24-26)

```nix
hasWallpapers = (myconfig.constants ? wallpapers) && (myconfig.constants.wallpapers != [ ]);
fallbackWallpaper = ../../../templates/src/wallpapers/nix-black-4k.png;
lockWallpaper = if hasWallpapers then "screenshot" else "${fallbackWallpaper}";
```

- If host has `wallpapers` defined → uses screenshot + blur (existing behavior)
- If host has no wallpapers → uses static nix logo wallpaper

### UI Elements Added

#### Background Section
```nix
background = lib.mkForce [
  {
    path = lockWallpaper;
    color = ch.base00;      # Dark background fallback
    blur_passes = 2;
    blur_size = 8;
  }
];
```

#### Username Box Shape (rectangular border around username)
```nix
shape = lib.mkForce [
  {
    size = "300, 50";
    rounding = 0;
    border_size = 2;
    color = "rgba(${c.base01}, 0.33)";         # Semi-transparent dark fill
    border_color = "rgba(${c.base03}, 0.95)";  # Visible border
    position = "0, 270";
    halign = "center";
    valign = "bottom";
  }
];
```

#### Labels (Time, Date, Username)
```nix
label = lib.mkForce [
  # Time display (large clock at top)
  {
    text = ''cmd[update:1000] echo "$(date +'%k:%M')"'';
    font_size = 115;
    font_family = "JetBrainsMono Nerd Font Bold";
    shadow_passes = 3;
    color = "rgba(${c.base05}, 0.9)";
    position = "0, -150";
    halign = "center";
    valign = "top";
  }
  # Date display (below time)
  {
    text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -"'';
    font_size = 18;
    font_family = "JetBrainsMono Nerd Font";
    shadow_passes = 3;
    color = "rgba(${c.base05}, 0.9)";
    position = "0, -350";
    halign = "center";
    valign = "top";
  }
  # Username label (inside the shape box)
  {
    text = "  $USER";    # User icon + username
    font_size = 15;
    font_family = "JetBrainsMono Nerd Font Bold";
    color = ch.base05;              # Solid color, no alpha
    position = "0, 284";
    halign = "center";
    valign = "bottom";
  }
];
```

#### Password Input Field
```nix
input-field = lib.mkForce [
  {
    size = "300, 50";
    rounding = 0;
    outline_thickness = 2;
    dots_spacing = 0.4;

    font_family = "JetBrainsMono Nerd Font Bold";
    font_color = "rgba(${c.base05}, 0.9)";

    outer_color = "rgba(${c.base03}, 0.95)";      # Border
    inner_color = "rgba(${c.base01}, 0.33)";      # Background
    check_color = "rgba(${c.base0B}, 0.95)";      # Success (green)
    fail_color = "rgba(${c.base08}, 0.95)";       # Error (red)
    capslock_color = "rgba(${c.base0A}, 0.95)";   # Capslock warning (yellow)
    bothlock_color = "rgba(${c.base0A}, 0.95)";   # Numlock+Capslock (yellow)

    hide_input = false;
    fade_on_empty = false;
    placeholder_text = ''<i><span foreground="${ch.base05}">Enter Password</span></i>'';

    position = "0, 200";
    halign = "center";
    valign = "bottom";
  }
];
```

### Important: lib.mkForce Usage

`lib.mkForce` is required on `shape`, `label`, and `input-field` because catppuccin-nix also defines these. Without `mkForce`, you get "defined multiple times" errors.

---

## 3. SDDM Pixie Base16 Accent Color

**File:** `/home/krit/nix/modules/nixos/services/sddm/sddm-pixie.nix`

### Changes Made

**Line 4:** Added `config` to module arguments
```nix
{ delib, pkgs, lib, config, ... }:
```

**Inside `nixos.ifEnabled` let block:** Added accent color extraction
```nix
accentColor = config.lib.stylix.colors.withHashtag.base0E;
```

**Modified `effectiveThemeConfig`:** Now includes base16 accent in merge chain
```nix
effectiveThemeConfig =
  { background = "assets/background.jpg"; }  # Default fallback
  // { accentColor = accentColor; }          # Base16 accent from stylix (NEW)
  // cfg.themeConfig                         # User overrides (can override accent)
  // (lib.optionalAttrs (cfg.background != null) { background = "assets/${bgFilename}"; });
```

### Merge Order

1. Default background path
2. Base16 accent color (`base0E`)
3. User's `themeConfig` overrides (can override anything)
4. Custom background path if provided

User can still override accent via host config:
```nix
myconfig.services.sddm-pixie.themeConfig.accentColor = "#FF0000";
```

---

## 4. Bug Fixes (Pre-existing Terminal Constant Issues)

These files were using `terminal` as a string but it's now an attrset:

### `/home/krit/nix/users/krit/nixos/specializations/deep-focus.nix`

**Before:**
```nix
smartLaunch = app: if builtins.elem app termApps then "${c.terminal} --class ${app} -e ${app}" else app;
# ...
"[workspace 4 silent] ${c.terminal}"
# ...
"workspace 4, class:^(${c.terminal})$"
```

**After:**
```nix
term = c.terminal.name or "alacritty";
smartLaunch = app: if builtins.elem app termApps then "${term} --class ${app} -e ${app}" else app;
# ...
"[workspace 4 silent] ${term}"
# ...
"workspace 4, class:^(${term})$"
```

### `/home/krit/nix/hosts/Krits-MacBook-Pro/default.nix`

**Line 19 - Before:**
```nix
terminal = "kitty";
```

**After:**
```nix
terminal.name = "kitty";
```

### `/home/krit/nix/hosts/nixos-laptop/default.nix`

**Line 89 - Before:**
```nix
terminal = myTerminal;
```

**After:**
```nix
terminal.name = myTerminal;
```

---

## Base16 Color Reference

| Code | Purpose | Gruvbox Example | Usage |
|------|---------|-----------------|-------|
| `base00` | Background | `#1d2021` | Dark background |
| `base01` | Lighter BG | `#3c3836` | Box fills (with alpha) |
| `base02` | Selection | `#504945` | Selections |
| `base03` | Comments | `#665c54` | Borders, muted elements |
| `base04` | Dark FG | `#bdae93` | Secondary text |
| `base05` | Foreground | `#d5c4a1` | Primary text |
| `base06` | Light FG | `#ebdbb2` | Emphasized text |
| `base07` | Lightest | `#fbf1c7` | Highlights |
| `base08` | Red | `#fb4934` | Errors, fail_color |
| `base09` | Orange | `#fe8019` | Warnings |
| `base0A` | Yellow | `#fabd2f` | Capslock warning |
| `base0B` | Green | `#b8bb26` | Success, check_color |
| `base0C` | Cyan | `#8ec07c` | Info |
| `base0D` | Blue | `#83a598` | Primary accent |
| `base0E` | Magenta | `#d3869b` | Secondary accent (SDDM) |
| `base0F` | Brown | `#d65d0e` | Special |

---

## Quick Adjustment Guide

### Hyprlock Layout Positions

| Element | Current Position | Adjustment |
|---------|-----------------|------------|
| Time | `"0, -150"` (from top) | Decrease Y = move up |
| Date | `"0, -350"` (from top) | Decrease Y = move up |
| Username box | `"0, 270"` (from bottom) | Increase Y = move up |
| Username label | `"0, 284"` (from bottom) | Should be ~14px above box position |
| Password field | `"0, 200"` (from bottom) | Increase Y = move up |

### Hyprlock Color Adjustments

**More transparent:** Decrease alpha (e.g., `0.33` → `0.2`)
**More opaque:** Increase alpha (e.g., `0.33` → `0.6`)
**Different color:** Change `baseXX` code

### Hyprlock Font Adjustments

| Element | Current Size | Location |
|---------|--------------|----------|
| Time | `115` | First label block |
| Date | `18` | Second label block |
| Username | `15` | Third label block |

### Terminal Cursor Options

In host config `constants.terminal`:
```nix
cursorStyle = "block";   # or "beam" or "underline"
cursorBlink = true;      # or false
animation = true;        # enables starship transience (fish only)
```

---

## Verification Commands

```bash
# Dry build (quick check)
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --dry-run

# Full flake check
nix flake check

# Darwin build check
nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run

# After rebuild, test:
# - Super+L to lock screen → verify hyprlock styling
# - Reboot → verify SDDM accent color
# - Open terminal → verify cursor style
# - Run command in fish → verify transient prompt (if animation=true)
```

---

## Files Modified Summary

| File | Change Type |
|------|-------------|
| `modules/nixos/services/hypr/hyprlock.nix` | Major rewrite - base16 theming |
| `modules/nixos/services/sddm/sddm-pixie.nix` | Added base16 accent |
| `modules/nixos/programs/de-wm/hyprland/hyprland-main.nix` | Animation speed, border, gaps |
| `users/krit/nixos/specializations/deep-focus.nix` | Bug fix - terminal.name |
| `hosts/Krits-MacBook-Pro/default.nix` | Bug fix - terminal.name |
| `hosts/nixos-laptop/default.nix` | Bug fix - terminal.name + hyprland constants |

---

## 5. Hyprland Window Manager Changes

**File:** `/home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix`

### Animation Speed (DELIBERATELY SLOW FOR TESTING)

**Location:** Lines 161-185

```nix
animation = [
  "windows, 1, 15, easeOutExpo"           # SLOW: change back to 4
  "windowsIn, 1, 15, easeOutBack, popin 80%"  # SLOW: change back to 4
  "windowsOut, 1, 12, easeOutExpo, popin 80%" # SLOW: change back to 3
  "fade, 1, 10, easeOutExpo"              # SLOW: change back to 3
  "border, 1, 5, easeOutExpo"
  "workspaces, 1, 12, easeInOutQuad, slide"   # SLOW: change back to 4
];
```

**To restore normal speeds:**
| Animation | Current (SLOW) | Normal |
|-----------|----------------|--------|
| windows | 15 | 4 |
| windowsIn | 15 | 4 |
| windowsOut | 12 | 3 |
| fade | 10 | 3 |
| workspaces | 12 | 4 |

### Inactive Window Border (REMOVED)

**Location:** Lines ~130-131

```nix
# No border on inactive/unfocused windows (fully transparent)
"col.inactive_border" = lib.mkForce "rgba(00000000)";
```

- Uses `lib.mkForce` to override catppuccin-nix setting
- `rgba(00000000)` = fully transparent (invisible border)
- Focused window keeps its colored border (`col.active_border` using base0D)

### Gaps (ALWAYS PRESENT, EVEN WITH SINGLE WINDOW)

**Changes made:**

1. **Removed windowrule that killed borders for single window:**
   ```nix
   # REMOVED: "bordersize 0, floating:0, onworkspace:w[t1]"
   ```

2. **Removed workspace rule that killed gaps for single window:**
   ```nix
   # REMOVED: "w[tv1], gapsout:0, gapsin:0"
   # KEPT: "f[1], gapsout:0, gapsin:0" (only fullscreen removes gaps)
   ```

3. **Gap settings use same value for both in and out:**
   ```nix
   gaps_in = myconfig.constants.hyprland.gap or 0;   # Between windows
   gaps_out = myconfig.constants.hyprland.gap or 0;  # Between windows and screen edges
   ```

### Host Gap Configuration

**nixos-desktop** (`hosts/nixos-desktop/default.nix` lines 130-134):
```nix
hyprland = {
  rounding = 10;
  gap = 5;  # 5px gap everywhere
  terminalOpacity = 0.85;
};
```

**nixos-laptop** (`hosts/nixos-laptop/default.nix` - NEWLY ADDED):
```nix
hyprland = {
  rounding = 10;
  gap = 5;  # 5px gap everywhere
  terminalOpacity = 0.85;
};
```

### To Adjust Gaps

Change `gap = 5` in host config to desired value. This sets:
- Gap between windows (gaps_in)
- Gap between windows and all screen edges (gaps_out)
- Works on landscape AND portrait monitors
- Works with single window too

### To Restore Old Behavior

If you want to remove gaps when only one window:
1. Add back to workspace rules:
   ```nix
   "w[tv1], gapsout:0, gapsin:0"
   ```

If you want to remove border when only one window:
1. Add back to windowrulev2:
   ```nix
   "bordersize 0, floating:0, onworkspace:w[t1]"
   ```

---

## 6. Waybar Ricing (2026-03-28)

### Overview

Complete waybar redesign with pill-shaped modules, transparent background, and base16 theming.

**Files Modified:**
- `modules/nixos/programs/waybar/waybar.nix`
- `modules/nixos/programs/waybar/style.css`

### Visual Design

- **Pill-shaped modules**: `border-radius: 20px` on all modules
- **No bottom outline**: Removed all `border-bottom` accent lines
- **Solid background**: All modules use `@base01` background color
- **Text color**: `@base05` for visibility against background
- **Transparent bar**: Wallpaper shows through between modules
- **Spacing**: `margin: 2px 5px` between modules (5px horizontal gap)
- **Padding**: `padding: 0 16px` inside all modules (consistent)

### Module Layout

```
LEFT: workspaces
CENTER: clock, window-title
RIGHT: language, weather, connectivity, pulseaudio, battery, notification
```

### New Modules Added

**Connectivity Module** (`custom/connectivity`):
- Shows WiFi SSID or "hostname" for ethernet
- Shows Bluetooth on/off status
- Format: `󰤨 WiFi-Name : 󰂯`
- Click: opens nm-connection-editor
- Right-click: opens blueman-manager

**Notification Module** (`custom/notification`):
- Only appears when `services.swaync.enable = true`
- Shows notification count with icon
- Click: toggles swaync notification center
- Right-click: clears all notifications

### CSS Structure

```css
/* All modules share these properties */
#clock, #battery, #pulseaudio, #language,
#custom-weather, #custom-connectivity, #custom-notification {
  padding: 0 16px;
  margin: 2px 5px;
  background-color: @base01;
  border-radius: 20px;
  border: none;
  color: @base05;
}
```

### Bar Dimensions

```nix
height = 36;
margin-top = 12;      # Gap from screen edge
margin-bottom = 12;   # Gap to apps below
margin-left = 10;
margin-right = 10;
```

### Known Issue: Ghost Module

**Problem**: There is a ghost/empty pill-shaped element appearing to the right of the window title in the center section.

**Location**: Visible in center of waybar, to the right of the app name

**Status**: NOT YET FIXED - needs investigation

**Suspected cause**: The generated waybar config shows both `hyprland/window` AND `niri/window` in modules-center (line 96-100 of `~/.config/waybar/config`). At runtime, only one should have content, but both may be rendering as empty modules.

---

## 7. Kitty Cursor Trail Animation

**File:** `users/krit/common/programs/terminal-emulators/kitty.nix`

### Settings Added (lines 48-51)

```nix
cursor_trail = 3;                    # Trail duration in cells (higher = longer trail)
cursor_trail_decay = "0.1 0.4";      # Fade timing: start slow, end faster
cursor_trail_start_threshold = 2;    # Minimum distance to trigger trail
```

### What It Does

When the cursor jumps (e.g., pressing Enter, navigating with arrows), a smooth trailing animation shows the movement path. Makes cursor position changes clearly visible.

### Adjustment Guide

| Setting | Effect | Example Values |
|---------|--------|----------------|
| `cursor_trail` | Trail length | 1 (short) → 5 (long) |
| `cursor_trail_decay` | Fade speed | "0.05 0.2" (fast) → "0.2 0.6" (slow) |
| `cursor_trail_start_threshold` | Min jump distance | 1 (any) → 5 (only long jumps) |

---

## 8. Hyprland Window Shadows

**File:** `modules/nixos/programs/de-wm/hyprland/hyprland-main.nix`

### Shadow Settings (decoration block)

```nix
shadow = {
  enabled = true;
  range = 15;                              # Shadow spread distance
  render_power = 3;                        # Falloff curve (1-4)
  color = lib.mkForce "rgba(00000080)";   # 50% black (uses mkForce for catppuccin override)
  offset = "0 4";                          # Slight downward offset
};
```

### Why `lib.mkForce`

The catppuccin-nix module also sets `shadow.color`, causing a conflict. `lib.mkForce` overrides the catppuccin value.

---

## 9. Current Visual Settings Summary

All these features are working well. User may request adjustments to:

| Feature | Current State | File |
|---------|---------------|------|
| Hyprland animations | Commented with speed values | hyprland-main.nix |
| Hyprland gaps | `gap = 3` in host config | hosts/*/default.nix |
| Hyprland shadows | 15px range, 50% opacity | hyprland-main.nix |
| Hyprland borders | 5px, inactive = transparent | hyprland-main.nix |
| Waybar modules | Pill-shaped, 20px radius | style.css |
| Waybar spacing | 5px between, 12px margins | waybar.nix + style.css |
| Cursor trail | 3 cells, smooth decay | kitty.nix |

### Future Adjustment Requests Expected

The user will likely ask to:
- Make animations slower/faster (change speed values in animation array)
- Adjust gap sizes (change `hyprland.gap` in host constants)
- Modify waybar spacing (change margin values in CSS)
- Tweak cursor trail duration/speed
- Fix the ghost module issue in waybar center
