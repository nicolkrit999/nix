{ delib
, inputs
, moduleSystem
, lib
, ...
}:
delib.module {
  name = "programs.zen.browser";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [ inputs.zen-browser.homeModules.beta ];
  };

  home.ifEnabled = { myconfig, ... }: {
    imports = lib.optional (myconfig.stylix.enable or false) {
      stylix.targets.zen-browser.profileNames = [ myconfig.constants.user ];
    };

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false;
    } // lib.optionalAttrs (moduleSystem == "darwin") {
      darwinDefaultsId = "app.zen-browser.zen";
    };
  };
}
