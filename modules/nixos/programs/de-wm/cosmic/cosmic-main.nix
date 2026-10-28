{ delib
, lib
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "programs.cosmic";

  options =
    with delib;
    moduleOptions {
      extraBinds = attrsOption { };
      # COSMIC defaults duplicating our binds: lock (our Super+Delete), logout (our Super+Shift+Delete),
      # close (our Super+Shift+C), fullscreen (our Super+M), terminal (our Super+Return)
      disabledDefaults = listOfOption lib.types.str [ "Super+Escape" "Super+Shift+Escape" "Super+q" "Super+F11" "Super+t" ];
      monitors = listOfOption
        (submodule {
          options = {
            output = strOption "*";
            width = intOption 0;
            height = intOption 0;
            refresh = numberOption 0;
            scale = numberOption 1.0;
            x = intOption 0;
            y = intOption 0;
            transform = enumOption [ 0 90 180 270 ] 0;
            enable = boolOption true;
          };
        })
        [{ output = "*"; }];
    };

  nixos.always = _: {
    home-manager.sharedModules = [
      inputs.cosmic-manager.homeManagerModules.cosmic-manager
    ];
  };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.cosmic-manager.homeManagerModules.cosmic-manager
    ];
  };

  home.ifEnabled =
    { myconfig, ... }:
    {
      # Enable data control for clipboard tools
      home.sessionVariables = {
        COSMIC_DATA_CONTROL_ENABLED = 1;
        XDG_SCREENSHOTS_DIR = myconfig.constants.screenshots;
      };
    };
}
