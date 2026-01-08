{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.cosmic or false) {
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

    # 3. System76 Scheduler (Performance)
    # Improves responsiveness on desktop, even for non-System76 hardware.
    services.system76-scheduler.enable = true;
  };
}
