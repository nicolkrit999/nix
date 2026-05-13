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
    { ...
    }:
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
              name = "vicinae-light";
              icon_theme = "default";
            };
            dark = {
              name = "vicinae-dark";
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
          power-profile
        ];

        themes = { };
      };
    };
}
