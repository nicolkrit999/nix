# TEMPLATE-HOST MINIMAL CONFIGURATION
# This template shows a minimal configuration of the current setup.
# It is as barebone as possible, allowing the user to customize it to their liking.
# Note that some important features for theming and functionality are not enabled here, so the configuration builds but is "broken".

{ delib
, inputs
, ...
}:
delib.host {
  name = "template-host-minimal";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    _:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        # Must equal homeManagerUser in flake.nix, which is hardcoded there because it is evaluated first.
        user = "krit";

        # Optional examples:
        # hostname = "my-computer";
        # gitUserName = "Your Name";
        # gitUserEmail = "you@example.com";
        # keyboardLayout = "us";
        # keyboardVariant = "";

        homeStateVersion = "26.05";
      };
    };

  # ---------------------------------------------------------------
  # ⚙️ SYSTEM-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  nixos =
    _:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "25.11";
      imports = [
        inputs.disko.nixosModules.disko
        ./hardware-configuration.nix
        # Uncomment exactly one disko config (it is the switch; also remove it from baseExclude in flake.nix)
        #./disko-config-btrfs.nix
        #./disko-config-btrfs-luks-impermanence.nix
      ];

    };

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  # home.username, home.homeDirectory and home.stateVersion come from
  # constants.user / constants.homeStateVersion via modules/nixos/toplevel/home-nixos.nix.
}
