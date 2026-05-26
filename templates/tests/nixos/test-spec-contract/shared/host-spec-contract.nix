{ delib, ... }:
delib.host {
  name = "spec-contract";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    # Enabled so specializations' lib.mkForce false is a real override:
    programs.hyprland.enable = true; # guest/safe-mode/secure-travel/entertainment disable
    programs.caelestia.enable = true; # guest/safe-mode/secure-travel disable
    programs.noctalia.enable = true; # guest/safe-mode disable
    programs.nix-ld.enable = true; # guest/secure-travel disable
    programs.nix-alien.enable = true; # guest/secure-travel disable
    programs.claude-code.enable = true; # guest/secure-travel disable
    programs.claude-desktop.enable = true; # guest disables
    bluetooth.enable = true; # guest/secure-travel disable
    services.tailscale.enable = true; # secure-travel disables

    # Global specializations
    specializations.deep-focus.enable = true;
    specializations.guest.enable = true;
    specializations.safe-mode.enable = true;
    specializations.secure-travel.enable = true;

    # krit specializations
    krit.specializations.entertainment.enable = true;
    krit.specializations.home.enable = true;
    krit.specializations.school.enable = true;
  };
}
