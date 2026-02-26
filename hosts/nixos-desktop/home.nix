{ delib, inputs, pkgs, ... }:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
delib.host {
  name = "nixos-desktop";

  home = {
    home.stateVersion = "25.11";

    home.packages = (with pkgs; [ winboat ]) ++ (with pkgs-unstable; [ ]);

    xdg.userDirs = {
      publicShare = null;
      music = null;
    };

    home.activation = {
      createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/Pictures/wallpapers || true
        mkdir -p $HOME/momentary || true
        mkdir -p $HOME/web-clients || true
      '';
    };
  };
}
