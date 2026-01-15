{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
  cssVariables = ''
    @define-color base00 ${c.base00}; 
    @define-color base01 ${c.base01};
    @define-color base02 ${c.base02};
    @define-color base03 ${c.base03};
    @define-color base04 ${c.base04};
    @define-color base05 ${c.base05}; 
    @define-color base06 ${c.base06};
    @define-color base07 ${c.base07};
    @define-color base08 ${c.base08}; 
    @define-color base09 ${c.base09};
    @define-color base0A ${c.base0A};
    @define-color base0B ${c.base0B}; 
    @define-color base0C ${c.base0C}; 
    @define-color base0D ${c.base0D};
    @define-color base0E ${c.base0E};
    @define-color base0F ${c.base0F};
  '';
  cssContent = builtins.readFile ./style.css;
in
{
  config = lib.mkIf ((vars.hyprland or false) && !(vars.caelestia or false)) {

    programs.waybar = {
      enable = true;
      style = lib.mkAfter ''
        ${cssVariables}
        ${cssContent}
      '';

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 40;
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "hyprland/language"
            "custom/weather"
            "pulseaudio"
            "battery"
            "clock"
            "tray"
          ];

          # Workspaces Icon and layout
          # A user may define host-specific icons (optional) in vars.waybarWorkspaceIcons
          "hyprland/workspaces" = {
            disable-scroll = true;
            show-special = true;
            special-visible-only = true;
            all-outputs = false;
            format = "{name} {icon}";
            format-icons = vars.waybarWorkspaceIcons or { };
          };

          # Languages flags and/or text
          # A user may define host-specific layout text (optional) in vars.waybarLayout
          "hyprland/language" = {
            min-length = 5;
            tooltip = true;
            on-click = "hyprctl switchxkblayout all next";
          }
          // vars.waybarLayout or { };

          # Weather module with wttr.in
          # It fetches the location from variables.nix and when clicked the favorite browser opens wttr.in page
          "custom/weather" = {
            format = "<span color='${c.base0C}'>${vars.weather}:</span> {} ";
            exec =
              let
                unit = if (vars.useFahrenheit or false) then "°C" else "°F";
              in
              "curl -s 'wttr.in/${vars.weather}?format=%c%t&${unit}' | sed 's/ //'";
            interval = 300;
            class = "weather";
            on-click = ''xdg-open "https://wttr.in/${vars.weather}"'';
          };

          "pulseaudio" = {
            format = "<span color='${c.base0D}'>{icon}</span> {volume}%";
            format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}% ";
            format-muted = "<span color='${c.base08}'></span> Muted";
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
              ];
            };
            on-click = "pavucontrol";
          };

          "battery" = {
            states = {
              warning = 20;
              critical = 5;
            };
            format = "<span color='${c.base0A}'>{icon}</span> {capacity}%";
            format-charging = "<span color='${c.base0B}'></span> {capacity}%";
            format-alt = "{time} <span color='${c.base0A}'>{icon}</span>";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          "clock" = {
            format = "{:%A, %B %d at %I:%M %p}"; # Click Format: Full Day Name, Month, Date... When the module is clicked it switches between formats
            format-alt = "{:%m/%d/%Y - %I:%M %p}"; # Standard Format: MM/DD/YYYY - HH:MM AM/PM
            tooltip-format = "<tt><small>{calendar}</small></tt>"; # Tooltip Format: Small calendar in tooltip
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
            };
          };

          # General app tray settings
          "tray" = {
            icon-size = 20;
            spacing = 8;
          };
        };
      };
    };
  };
}
