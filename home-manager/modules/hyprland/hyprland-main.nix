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
          "sh -lc 'SIG=$(hyprctl instances | head -n 1 | cut -d \" \" -f 2); systemctl --user set-environment HYPRLAND_INSTANCE_SIGNATURE=\"$SIG\" WAYLAND_DISPLAY=\"$WAYLAND_DISPLAY\" XDG_RUNTIME_DIR=\"$XDG_RUNTIME_DIR\"'"

          "wl-paste --type text --watch cliphist store" # Start clipboard manager for text
          "wl-paste --type image --watch cliphist store" # Start clipboard manager for images
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # Keep for snapper polkit support
          "pkill ibus-daemon" # Kill ibus given by gnome
        ]
        ++ lib.optionals (!(vars.caelestia or false)) [
          "uwsm app -- waybar" # Start waybar only if "caelestia" is disabled in variables.nix
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
        ];

        workspace = [
          "w[tv1], gapsout:0, gapsin:0" # No gaps if only 1 window is visible
          "f[1], gapsout:0, gapsin:0" # No gaps if window is fullscreen
        ]
        ++ (vars.hyprlandWorkspaces or [ ]);
      };
    };
  };
}
