{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.cosmic";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =

    {
      services.desktopManager.cosmic.enable = true;

      environment.cosmic.excludePackages = with pkgs; [
        cosmic-term
        cosmic-store
        cosmic-applibrary
        cosmic-edit
        cosmic-files
        cosmic-player
      ];

      services.displayManager.cosmic-greeter.enable = false;

      services.desktopManager.cosmic.showExcludedPkgsWarning = false;
    };
}
