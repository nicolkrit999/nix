{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.hyprland";
  options =
    with delib;
    moduleOptions {
      monitors = listOfOption str [ ",preferred, auto,1" ];
      execOnce = listOfOption str [ ];
      monitorWorkspaces = listOfOption str [ ];
      windowRules = listOfOption str [ ];
      extraBinds = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      term = myconfig.constants.terminal.name or "alacritty";
      rawFm = myconfig.constants.fileManager or "dolphin";
      rawEd = myconfig.constants.editor or "vscode";

      # List of known terminal-based apps. Add more as needed
      termApps = [
        "nvim"
        "neovim"
        "vim"
        "nano"
        "hx"
        "helix"
        "yazi"
        "ranger"
        "lf"
        "nnn"
      ];

      smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
      smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;
    in

    {
      # ----------------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      catppuccin.hyprland.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprland.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprland.accent = myconfig.constants.theme.catppuccinAccent or "mauve";
      # ----------------------------------------------------------------------------

      home.packages = with pkgs; [
        kdePackages.gwenview # Default image viewer
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
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };

        settings = {
          env =
            let
              firstMonitor = if builtins.length cfg.monitors > 0 then builtins.head cfg.monitors else "";
              monitorParts = lib.splitString "," firstMonitor;
              rawScale = if (builtins.length monitorParts) >= 4 then builtins.elemAt monitorParts 3 else "1";
              gdkScale = if rawScale != "1" && rawScale != "1.0" then "2" else "1";
            in
            [
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

              # SYSTEM PATHS
              "XDG_SCREENSHOTS_DIR,${myconfig.constants.screenshots}" # Tells tools where to save screenshots by default.
            ];

          monitor = cfg.monitors;

          "$Mod" = "SUPER";
          "$terminal" = term;
          "$browser" = myconfig.constants.browser or "firefox";
          "$fileManager" = smartFm;
          "$editor" = smartEd;
          "$menu" = "walker";
          "$shellMenu" =
            if myconfig.programs.caelestia.enableOnHyprland or false then
              "caelestiaQS"
            else if myconfig.programs.noctalia.enableOnHyprland or false then
              "noctalia-shell ipc call toggleAppLauncher"
            else
              "walker";

          exec-once = [
            "${pkgs.bash}/bin/bash $HOME/.local/bin/init-gnome-keyring.sh"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            "pkill ibus-daemon"
          ]
          ++ cfg.execOnce;

          general = {
            gaps_in = myconfig.constants.hyprland.gap or 0;
            gaps_out = myconfig.constants.hyprland.gap or 0;
            border_size = 5; # Thickness of window borders

            "col.active_border" =
              if myconfig.constants.theme.catppuccin then
                "$accent"
              else
                "rgb(${config.lib.stylix.colors.base0D})";

            # No border on inactive/unfocused windows (fully transparent)
            "col.inactive_border" = lib.mkForce "rgba(00000000)";

            resize_on_border = true;

            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = myconfig.constants.hyprland.rounding or 0; # Corner radius in pixels for window borders
            active_opacity = 1.0; # Opacity of focused windows (1.0 = fully opaque)
            inactive_opacity = 1.0; # Opacity of unfocused windows (1.0 = fully opaque)
            shadow = {
              enabled = true; # Enable drop shadows on all windows
              range = 15; # Shadow spread distance in pixels
              render_power = 3; # Shadow falloff curve (1-4, higher = sharper edge)
              color = lib.mkForce "rgba(00000080)"; # Shadow color with 50% opacity
              offset = "0 4"; # Shadow offset: x y (pixels down and right)
            };

            blur = {
              enabled = false; # Disable blur effect behind transparent windows
            };
          };

          animations = {
            enabled = true; # Master toggle for all animations

            # Bezier curves define the acceleration/deceleration pattern
            # Format: "name, x1, y1, x2, y2" (control points for cubic bezier)
            bezier = [
              "easeOutExpo, 0.16, 1, 0.3, 1" # Fast start, slow end (exponential ease-out)
              "easeInOutQuad, 0.45, 0, 0.55, 1" # Symmetric acceleration (quadratic ease-in-out)
              "easeOutBack, 0.34, 1.56, 0.64, 1" # Overshoot then settle (bouncy feel)
            ];

            # Animation format: "type, enabled, speed, curve, [style]"
            # Speed: lower = faster (e.g., 4 = ~100ms, 10 = ~250ms at 60fps)
            animation = [
              "windows, 1, 4, easeOutExpo" # Default window move/resize (speed 4 ≈ 100ms)
              "windowsIn, 1, 4, easeOutBack, popin 80%" # Window open: pop in from 80% scale
              "windowsOut, 1, 3, easeOutExpo, popin 80%" # Window close: pop out to 80% scale (faster)
              "fade, 1, 3, easeOutExpo" # Opacity transitions (speed 3 ≈ 75ms)
              "border, 1, 5, easeOutExpo" # Border color changes (speed 5 ≈ 125ms)
              "workspaces, 1, 4, easeInOutQuad, slide" # Workspace switch: slide animation
            ];
          };

          input = {
            kb_layout = myconfig.constants.keyboardLayout or "us";
            kb_variant = myconfig.constants.keyboardVariant or "";
            kb_options = "grp:ctrl_alt_toggle"; # Ctrl+Alt to switch layout
            touchpad = {
              natural_scroll = false;
            };
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
            # Removed "bordersize 0" rule - we want focused window to always have border
            # Inactive windows have transparent border via col.inactive_border

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

            "float, class:^(xdg-desktop-portal-kde)$"
            "center, class:^(xdg-desktop-portal-kde)$"
            "size 50% 50%, class:^(xdg-desktop-portal-kde)$"

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
          ++ (lib.optional
            ((myconfig.constants.hyprland.terminalOpacity or 1.0) < 1.0)
            "opacity ${toString myconfig.constants.hyprland.terminalOpacity} override, class:^(${term})$"
          )
          ++ cfg.windowRules;

          workspace = [
            # Removed "w[tv1], gapsout:0, gapsin:0" - we want gaps even with single window
            "f[1], gapsout:0, gapsin:0" # No gaps only if window is fullscreen
          ]
          ++ (cfg.monitorWorkspaces or [ ]);
        };
      };
    };
}
