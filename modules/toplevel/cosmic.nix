{
  delib,
  pkgs,
  lib,
  config,
  ...
}:
delib.module {
  name = "cosmic";
  options.cosmic = with delib; {
    enable = boolOption false;
  };

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

      # Disable cosmic-greeter since sddm is used instead.
      services.displayManager.cosmic-greeter.enable = false;

      # Disable the warning about excluded packages since we manage them ourselves.
      services.desktopManager.cosmic.showExcludedPkgsWarning = false;
    };
}
