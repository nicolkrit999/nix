{ delib
, inputs
, pkgs
, ...
}:
delib.module {
  name = "programs.yazi.plugins";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [
      inputs.nix-yazi-plugins.legacyPackages.${pkgs.stdenv.hostPlatform.system}.homeManagerModules.default
    ];
  };

  home.ifEnabled = { ... }: {
    programs.yazi.enable = true;

    programs.yazi.yaziPlugins = {
      enable = true;
      plugins = {
        starship.enable = true;
        jump-to-char = {
          enable = true;
          keys.toggle.on = [ "F" ];
        };
        relative-motions = {
          enable = true;
          show_numbers = "relative_absolute";
          show_motion = true;
        };
      };
    };
  };
}
