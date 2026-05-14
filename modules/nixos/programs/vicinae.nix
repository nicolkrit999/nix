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
    extraRayCastExtensions = listOfOption lib.types.attrs [ ];
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
      mkRayCastExtension = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension;
      raycastRev = "83771ef261a0ef922c2a5353546430a29eceae17"; # Default commit of github:raycast/extensions. Override per-extension with rev = "..." in the host.
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
          pop_to_root_on_close = false;
          favicon_service = "twenty";
          search_files_in_root = false;

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
            layer_shell.layer = "overlay";
          };

          providers = { };
        };

        extensions = (with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
          nix
        ]) ++ cfg.extraExtensions
        ++ (map
          (ext:
            let
              installName = ext.installName or ext.name;
              base = builtins.removeAttrs ext [ "installName" ];
            in
            mkRayCastExtension ({ rev = raycastRev; } // base // {
              installPhase = ''
                runHook preInstall
                mkdir -p $out
                cp -r /build/.config/raycast/extensions/${installName}/* $out/
                runHook postInstall
              '';
            })
          )
          ([
            # global raycast extensions
          ] ++ cfg.extraRayCastExtensions));

        themes = { };
      };
    };
}
