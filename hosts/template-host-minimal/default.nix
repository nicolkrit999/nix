# TEMPLATE-HOST MINIMAL CONFIGURATION
# THIS IS A TEMPLATE THAT SHOW A MINIMAL CONFIGURATION OF THE CURRENT SETUP ALLOW
# It is as barebone as possible, allowing the user to customize it for it's liking
# Note that some important features for theming and functionality are not enabled here. Meaning the actual configuration would build but be "broken"

{ delib
, ...
}:
delib.host {
  name = "template-host-minimal";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        user = "krit"; # ⚠️ This is put because flake.nix hardcode the name and it can't be a variable since it's the first thing it's evaluated. Change as needed

        homeStateVersion = "26.05";
      };
    };

  # ---------------------------------------------------------------
  # ⚙️ SYSTEM-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  nixos =
    { ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "25.11";
      imports = [
        ./hardware-configuration.nix
        #./disko-config-btrfs.nix
        #./disko-config-btrfs-luks-impermanence.nix
      ];

    };

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  # home.stateVersion is now supplied by constants.homeStateVersion above via
  # modules/nixos/toplevel/home-nixos.nix - not repeated here to avoid a
  # double-definition of the same option.
  home = { ... }: {
    home.username = "krit";
    home.homeDirectory = "/home/krit";
  };
}
