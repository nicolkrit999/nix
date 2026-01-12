{ pkgs
, lib
, config
, vars
, ...
}:
let
  cssContent = builtins.readFile ./style.css;

  # Intelligently theme based on whatever catppuccin is enabled or not
  cssVariables =
    if vars.catppuccin then
      ''
        @define-color accent @${vars.catppuccinAccent};
      ''
    else
      ''
        /* 🔴 BASE16 FALLBACK MODE */
        @define-color base   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color text   ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */

        @define-color accent ${config.lib.stylix.colors.withHashtag.base0D}; /* Default Accent */

        /* Map colors used in style.css to Base16 equivalents */
        @define-color red    ${config.lib.stylix.colors.withHashtag.base08};
        @define-color peach  ${config.lib.stylix.colors.withHashtag.base09}; /* Orange */
        @define-color green  ${config.lib.stylix.colors.withHashtag.base0B};
        @define-color teal   ${config.lib.stylix.colors.withHashtag.base0C}; /* Cyan */
        @define-color blue   ${config.lib.stylix.colors.withHashtag.base0D};
        @define-color mauve  ${config.lib.stylix.colors.withHashtag.base0E}; /* Purple */
      '';

in
{
  config = lib.mkIf ((vars.hyprland or false) && !(vars.caelestia or false)) {
    catppuccin.waybar.enable = vars.catppuccin;

    programs.waybar = {
      enable = true;

      # -----------------------------------------------------------------------
      # 🎨 STYLE CONFIGURATION
      # -----------------------------------------------------------------------
      style = lib.mkAfter ''
        ${cssVariables}
        ${cssContent}
      '';

      settings = {
        mainBar = {
          layer = "top"; # "top" layer puts it above normal windows
          position = "top"; # Position on screen (top, bottom, left, right)
          height = 40; # Height in pixels

          # Module Placement
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "hyprland/language"
            "custom/weather"
            "pulseaudio"
            "custom/music"
            "battery"
            "clock"
            "tray"
          ];

          # -----------------------------------------------------
          # 🗄️ Workspaces Module
          # -----------------------------------------------------
          "hyprland/workspaces" = {
            disable-scroll = true;
            show-special = true; # Show special workspaces (scratchpads)
            special-visible-only = true; # Only show special workspace if it's actually visible
            all-outputs = false; # Only show workspaces that live on the current monitor

            # Format for workspace names and icons
            format = "{name} {icon}";
            format-icons = vars.waybarWorkspaceIcons or { };
          };



          # -----------------------------------------------------
          # ⌨️ Keyboard Layout icons
          # The flag changes based on the current keyboard layout
          # -----------------------------------------------------
          "hyprland/language" = {
            min-length = 5; # prevent layout jumping when flag changes
            tooltip = true; # disable tooltip on hover
          }
          // vars.waybarLayoutFlags or { };

          # -----------------------------------------------------
          # ☁️ Weather
          # -----------------------------------------------------
          "custom/weather" = {
            format = "${vars.weather}: {} ";
            # Fetches weather for the defined city in flake.nix from wttr.in
            # %c = Condition icon, %t = Temperature
            exec =
              let
                unit = if (vars.useFahrenheit or false) then "°C" else "°F";
              in
              "curl -s 'wttr.in/${vars.weather}?format=%c%t&${unit}'";
            interval = 300; # Update every 5 minutes (300 seconds)
            class = "weather";
          };

          # -----------------------------------------------------
          # 🔊 Audio Volume (PulseAudio)
          # -----------------------------------------------------
          "pulseaudio" = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}% "; # Adds Bluetooth icon if connected
            format-muted = "";

            # Icons change based on device type
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
              ]; # Low vol / High vol
            };
            on-click = "pavucontrol"; # Open volume mixer on click
          };


          # -----------------------------------------------------
          # 🔋 Battery Status
          # If no battery is found (eg desktop pc), this module is hidden
          # -----------------------------------------------------
          "battery" = {
            states = {
              warning = 20; # Yellow warning at 20%
              critical = 5; # Red critical at 5%
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%"; # Show plug icon when charging
            format-alt = "{time} {icon}"; # Click to show Time Remaining
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ]; # Icons from empty to full
          };

          # -----------------------------------------------------
          # 🕒 Clock & Calendar
          # -----------------------------------------------------
          "clock" = {
            format = "{:%A, %B %d, %Y}";
            format-alt = "{:%m/%d/%Y - %I:%M %p}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = with config.lib.stylix.colors; {
                months = "<span color='#${base05}'><b>{}</b></span>";
                days = "<span color='#${base05}'><b>{}</b></span>";
                weeks = "<span color='#${base05}'><b>W{}</b></span>";
                today = "<span color='#${base0D}'><b><u>{}</u></b></span>";
              };
            };
          };

          # -----------------------------------------------------
          # 📥 System Tray
          # -----------------------------------------------------
          "tray" = {
            icon-size = 20; # Size of tray icons
            spacing = 1; # Space between tray icons
          };
        };
      };
    };
  };
}
