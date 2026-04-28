{ delib
, inputs
, moduleSystem
, lib
, ...
}:
delib.module {
  name = "programs.yazi.plugins";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem != "darwin") [
      inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default
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
