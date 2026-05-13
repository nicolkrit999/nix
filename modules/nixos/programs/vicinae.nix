{ delib
, inputs
, pkgs
, ...
}:
delib.module {
  name = "programs.vicinae";
  options = delib.singleEnableOption true;

  home.always = { ... }: {
    imports = [ inputs.vicinae.homeManagerModules.default ];
  };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      stylixEnabled = myconfig.stylix.enable;
    in
    {
      services.vicinae = {
        enable = true;
        package = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;

        systemd = {
          enable = true;
          autoStart = true;
          environment = {
            USE_LAYER_SHELL = 1;
          };
        };

        settings = {
          close_on_focus_loss = true;
          consider_preedit = true;
          pop_to_root_on_close = true;
          favicon_service = "twenty";
          search_files_in_root = true;

          font = {
            normal = {
              size = 12;
              family = "JetBrainsMono Nerd Font";
            };
          };

          theme = {
            light = {
              name = if stylixEnabled then "stylix" else "vicinae-light";
              icon_theme = "default";
            };
            dark = {
              name = if stylixEnabled then "stylix" else "vicinae-dark";
              icon_theme = "default";
            };
          };

          launcher_window = {
            opacity = 0.98;
          };

          providers = { };
        };

        extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
          bluetooth
          nix
          gnome-settings
          case-converter
          number-converter
          nerdfont-search
          github
          ssh
          pulseaudio
          kde-system-settings
          power-profile
          port-killer
          zoxide-recent-directories
          niri
          aria2-manager
          it-tools
          player-pilot
          #systemd
          fuzzy-files
          wifi-commander
          agent-skills-sh
          wikipedia
          podman
          agenda
          color-converter
          supergenpass
          process-manager
        ];

        themes = { };
      };
    };
}
