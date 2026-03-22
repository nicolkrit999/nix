# TEMPLATE-HOST MINIMAL CONFIGURATION
# THIS IS A TEMPLATE THAT SHOW A MINIMAL CONFIGURATION OF THE CURRENT SETUP ALLOW
# It is as barebon as possible, allow the user to customize it for it's liking
# Note that some important features for theming and functionality are not enabled here. Meaning the actual configuration would build but be "broken"
# For a reference on the bare minimum options to setup for a better experience look
# at ../hosts/template-host-full/default.nix and look for options that are enabled so ".enable = true"

{ delib
, inputs
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

      };

      # You can enable specific modules for this host here:
      # host.services.flatpak.enable = true;
      # host.services.local-packages.enable = true;
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
        # Note: niri and plasma-manager imports are handled automatically by their respective modules
        ./hardware-configuration.nix
      ];

      # Note: pathsToLink for xdg-desktop-portal is handled by modules/nixos/toplevel/xdg-portal.nix
    };

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  home = { ... }: {
    home.username = "krit";
    home.homeDirectory = "/home/krit";
    home.stateVersion = "25.11";

    # Note: niri and plasma-manager imports are handled automatically by their respective modules

    xdg.userDirs = {
      publicShare = null;
      music = null;
    };

    home.activation = {
      createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/Downloads"
      '';
    };
  };
}
