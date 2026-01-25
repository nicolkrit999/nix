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
    catppuccin.hyprland.enable = vars.catppuccin or false;
    catppuccin.hyprland.flavor = vars.catppuccinFlavor or "mocha";
    catppuccin.hyprland.accent = vars.catppuccinAccent or "mauve";
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
            firstMonitor = if builtins.length vars.monitors > 0 then builtins.head vars.monitors else "";
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
          kb_layout = vars.keyboardLayout or "us";
          kb_variant = vars.keyboardVariant or "";
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
