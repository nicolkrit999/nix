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

  nixos.ifEnabled = { ... }: {
    myconfig.stylix.targets."zen-browser".profileNames = [ "default" ];
  };

  home.ifEnabled = { ... }: {
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false;

      policies = {
        DisableTelemetry = true;
        DisableAppUpdate = true;
        DontCheckDefaultBrowser = true;
      };

      profiles.default = {
        # ⚠ CLOSE ZEN BEFORE REBUILD when modifying keyboardShortcuts.
        keyboardShortcuts = [
          {
            id = "zen-compact-mode-toggle";
            key = "m";
            modifiers = {
              alt = true;
              shift = true;
            };
          }
        ];
      };
    } // lib.optionalAttrs (moduleSystem == "darwin") {
      darwinDefaultsId = "app.zen-browser.zen";
    };
  };
}
