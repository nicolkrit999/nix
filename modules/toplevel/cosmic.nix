{
  delib,
  pkgs,
  ...
}:
delib.module {
  # TODO: probably can be renamed to "programs.cosmic" so that it's not enabled at all if the user does not want it
  name = "cosmic";
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

      # Disable cosmic-greeter since sddm is used instead.
      services.displayManager.cosmic-greeter.enable = false;

      # Disable the warning about excluded packages since we manage them ourselves.
      services.desktopManager.cosmic.showExcludedPkgsWarning = false;
    };
}
