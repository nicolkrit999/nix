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

    # The shipped zen-beta.desktop omits application/pdf (pdf.js renders it); no derivable desktop-id attr exists
    xdg.mimeApps.associations.added = lib.mkIf (moduleSystem != "darwin") {
      "application/pdf" = [ "zen-beta.desktop" ];
    };

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
