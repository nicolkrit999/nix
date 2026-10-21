{ delib
, inputs
, moduleSystem
, lib
, ...
}:
delib.module {
  name = "programs.zen.browser";

  options = delib.singleEnableOption false;

  home.always.imports = [ inputs.zen-browser.homeModules.beta ];

  myconfig.ifEnabled.stylix.targets."zen-browser".profileNames = [ "default" ];

  home.ifEnabled = {
    home.sessionVariables = lib.mkIf (moduleSystem != "darwin") { MOZ_ENABLE_WAYLAND = "1"; };

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false; # pinned on purpose, equals the upstream default

      policies = {
        DisableTelemetry = true;
        DisableAppUpdate = true;
        DontCheckDefaultBrowser = true;
      };

      profiles.default = { };
    } // lib.optionalAttrs (moduleSystem == "darwin") {
      darwinDefaultsId = "app.zen-browser.zen";
    };
  };
}
