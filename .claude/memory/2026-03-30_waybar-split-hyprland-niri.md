# Waybar Split: Hyprland & Niri (2026-03-30)

## What Was Done

Split the unified `programs.waybar` module into two completely isolated modules:
- `programs.waybar-hyprland` — Hyprland-only
- `programs.waybar-niri` — Niri-only

## File Structure

```
modules/nixos/programs/waybar/
├── hyprland/
│   ├── waybar-hyprland.nix
│   └── style.css
└── niri/
    ├── waybar-niri.nix
    └── style.css
```

## Key Design Decisions

### Separate Config Directories
Each waybar uses its own config directory to avoid conflicts when both compositors are enabled:
- `~/.config/waybar-hyprland/` (config + style.css)
- `~/.config/waybar-niri/` (config + style.css)

### Separate Systemd Services
- `waybar-hyprland.service` → binds to `hyprland-session.target`
- `waybar-niri.service` → binds to `niri.service`

### Does NOT use `programs.waybar`
The modules use `xdg.configFile` directly and create custom systemd services, avoiding home-manager's waybar module entirely. This prevents conflicts.

## Guard Logic

### waybar-hyprland
Active when: `hyprland.enable = true` AND `caelestia.enableOnHyprland = false` AND `noctalia.enableOnHyprland = false`

### waybar-niri
Active when: `niri.enable = true` AND `noctalia.enableOnNiri = false`
(No caelestia check — caelestia is hyprland-only)

## Host Configuration

In host default.nix files, waybar is now configured as:
```nix
programs.waybar-hyprland = {
  enable = true;
  waybarLayout = { ... };      # Keyboard layout flags
  waybarWorkspaceIcons = { ... }; # Hyprland workspace icons
};

programs.waybar-niri = {
  enable = true;
  waybarLayout = { ... };      # Keyboard layout flags
  # No waybarWorkspaceIcons — niri uses index format
};
```

## Cleanup Done

- Removed old waybar logic from `walker.nix` (walker is just a launcher, shouldn't manage waybar)
- Deleted original `waybar.nix` and `style.css` from the waybar root directory

## Truth Table Reference

| Hyprland | Niri | Caelestia (Hypr) | Noctalia (Hypr) | Noctalia (Niri) | waybar-hyprland | waybar-niri |
|----------|------|------------------|-----------------|-----------------|-----------------|-------------|
| ON | ON | OFF | OFF | OFF | **ON** | **ON** |
| ON | ON | **ON** | OFF | OFF | OFF | **ON** |
| ON | ON | OFF | **ON** | OFF | OFF | **ON** |
| ON | ON | OFF | OFF | **ON** | **ON** | OFF |
| etc... |
