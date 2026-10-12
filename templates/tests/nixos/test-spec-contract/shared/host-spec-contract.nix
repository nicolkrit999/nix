{ delib, ... }:
delib.host {
  name = "spec-contract";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    # Enabled so specializations' lib.mkForce false is a real override:
    programs = {
      hyprland.enable = true; # guest/safe-mode/secure-travel/entertainment disable
      caelestia.enable = true; # guest/safe-mode/secure-travel disable
      noctalia.enable = true; # guest/safe-mode disable
      nix-ld.enable = true; # guest/secure-travel disable
      nix-alien.enable = true; # guest/secure-travel disable
      claude-code.enable = true; # guest/secure-travel disable
      claude-desktop.enable = true; # guest/secure-travel disable
      codex.enable = true; # guest/secure-travel disable
      herdr.enable = true; # guest/secure-travel disable
      headroom.enable = true; # guest/secure-travel disable
      fastfetch.enable = true; # safe-mode disables
    };
    services = {
      hyprlock.enable = true; # guest disables
      tailscale.enable = true; # secure-travel disables
    };
    bluetooth.enable = true; # guest/secure-travel disable

    # Global specializations
    specializations = {
      deep-focus.enable = true;
      guest.enable = true;
      safe-mode.enable = true;
      secure-travel.enable = true;
    };

    krit = {
      programs.claude-code-wrappers.enable = true; # guest/secure-travel disable

      # krit specializations
      specializations = {
        entertainment.enable = true;
        home.enable = true;
        school.enable = true;
      };
    };
  };
}
