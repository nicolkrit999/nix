{ delib, inputs, pkgs, ... }:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
delib.host {
  name = "nixos-desktop"; # 🌟 Magic merge tag

  home = {
    home.stateVersion = "25.11";

    home.packages = (with pkgs; [ winboat ]) ++ (with pkgs-unstable; [ ]);

    xdg.userDirs = {
      publicShare = null;
      music = null;
    };

    home.activation = {
      createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/Pictures/wallpapers
        mkdir -p $HOME/momentary
      '';
    };
  };
}
