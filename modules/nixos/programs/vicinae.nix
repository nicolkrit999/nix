{ delib
, inputs
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.vicinae";
  options = with delib; moduleOptions {
    enable = boolOption true;
    extraExtensions = listOfOption lib.types.package [ ];
  };

  home.always = { ... }: {
    imports = [ inputs.vicinae.homeManagerModules.default ];
  };

  home.ifEnabled =
    { cfg
    , myconfig
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

        extensions = (with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
          nix
        ]) ++ cfg.extraExtensions;

        themes = { };
      };
    };
}
