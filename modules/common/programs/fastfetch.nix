{ delib
, pkgs
, lib
, config
, moduleSystem
, ...
}:
let
  isDarwin = moduleSystem == "darwin";
  splash = pkgs.writeShellScript "fastfetch-splash" ''
    for _ in $(${lib.getExe' pkgs.coreutils "seq"} 30); do
      ${lib.getExe' pkgs.coreutils "timeout"} 0.5 ${lib.getExe' pkgs.wireplumber "wpctl"} inspect @DEFAULT_AUDIO_SINK@ > /dev/null 2>&1 && break
      ${lib.getExe' pkgs.coreutils "sleep"} 0.1
    done
    exec fastfetch "$@"
  '';
in
delib.module {
  name = "programs.fastfetch";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    osIcon = delib.strOption (if isDarwin then "" else "󱄅");
    boxWidth = delib.intOption (if isDarwin then 69 else 70);
    generations = delib.strOption "";
    random = delib.boolOption true;
    pokemon = delib.strOption "pikachu";
    showName = delib.boolOption false;
    splashCommand = delib.strOption (if isDarwin then "fastfetch" else "${splash}");
  };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      # Category colours come from the stylix base16 palette:
      #   system -> base0D, desktop -> base0E, hardware -> base0B, connectivity -> base0C
      # Fallback (stylix disabled, e.g. some specialisations): ANSI names.
      stylixColors = config.lib.stylix.colors.withHashtag;
      hasPalette = (myconfig.stylix.enable or false) && ((config.lib.stylix or { }) ? colors);
      palette =
        if hasPalette then {
          system = stylixColors.base0D;
          desktop = stylixColors.base0E;
          hardware = stylixColors.base0B;
          connectivity = stylixColors.base0C;
        } else {
          system = "blue";
          desktop = "magenta";
          hardware = "green";
          connectivity = "cyan";
        };
      bar = lib.concatStrings (lib.replicate cfg.boxWidth "━");
      line = color: text: {
        type = "custom";
        format = "{#${palette.${color}}}${text}{#}";
      };
      header = title: color:
        let
          label = "━ ${title} ";
          fill = lib.concatStrings (lib.replicate (cfg.boxWidth - (3 + lib.stringLength title)) "━");
        in
        line color "┏${label}${fill}┓";
      footer = color: line color "┗${bar}┛";
      entry = type: icon: color: {
        inherit type;
        keyIcon = "  ${icon}";
        keyColor = palette.${color};
      };
      pokemonExe = lib.getExe pkgs.pokemon-colorscripts;
      pokemonArgs =
        lib.optional (!cfg.showName) "--no-title"
        ++ (
          if cfg.random
          then [ "-r" ] ++ lib.optional (cfg.generations != "") (lib.escapeShellArg cfg.generations)
          else [ "-n" (lib.escapeShellArg cfg.pokemon) ]
        );
    in
    {
      assertions = [
        {
          assertion = cfg.random || cfg.generations == "";
          message = "programs.fastfetch.generations only applies when programs.fastfetch.random is true";
        }
      ];

      home.packages = [ pkgs.pokemon-colorscripts ];

      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            type = "command-raw";
            source = lib.concatStringsSep " " ([ (lib.escapeShellArg pokemonExe) ] ++ pokemonArgs);
            padding.top = 3;
          };
          display = {
            separator = "    ";
            key.type = "icon";
          };
          modules = [
            (header "System" "system")
            "break"
            ((entry "title" "󰀄" "system") // {
              key = "title";
              color = {
                user = palette.system;
                at = palette.system;
                host = palette.desktop;
              };
            })
            (entry "os" "${cfg.osIcon}" "system")
            (entry "kernel" "" "system")
            (entry "uptime" "" "system")
            (entry "packages" "󰏖" "system")
            (entry "locale" "" "system")
            "break"
            (footer "system")
            "break"
            (header "Desktop" "desktop")
            "break"
            (entry "de" "󰟀" "desktop")
            (entry "wm" "󰨇" "desktop")
            (entry "theme" "󰉼" "desktop")
            (entry "icons" "󰀻" "desktop")
            (entry "cursor" "󰆿" "desktop")
            (entry "font" "󰛖" "desktop")
            (entry "terminal" "" "desktop")
            (entry "shell" "" "desktop")
            "break"
            (footer "desktop")
            "break"
            (header "Hardware" "hardware")
            "break"
            (entry "host" "" "hardware")
            (entry "cpu" "" "hardware")
            (entry "gpu" "󱤓" "hardware")
            (entry "memory" "󰍛" "hardware")
            (entry "swap" "󰓡" "hardware")
            (entry "disk" "" "hardware")
            (entry "display" "󰍹" "hardware")
            (entry "battery" "󰁹" "hardware")
            "break"
            (footer "hardware")
            "break"
            (header "Connectivity & Audio" "connectivity")
            "break"
            (entry "wifi" "" "connectivity")
            (entry "sound" "" "connectivity")
            "break"
            (footer "connectivity")
          ];
        };
      };
    };
}
