{ delib
, inputs
, pkgs
, ...
}:
delib.module {
  name = "krit.home.base";
  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }: {
    home.stateVersion = "25.11";
    home.username = myconfig.constants.user;
    home.homeDirectory = "/home/${myconfig.constants.user}";

    home.packages = with pkgs; [
      efibootmgr
      fastfetch
      fd
      gh
      htop
      inetutils
      killall
      nix-search-cli
      pay-respects
      pokemon-colorscripts
      ripgrep
      stow
      tmate
      tree
      unzip
      vscode
      yt-dlp
      zip
      zlib
    ];

    xdg.userDirs = {
      publicShare = null;
      music = null;
    };

    home.activation.createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers || true
      mkdir -p $HOME/momentary || true
      mkdir -p $HOME/.distrobox-bin || true
      mkdir -p $HOME/.config/portainer-mcp || true
      mkdir -p $HOME/github-repos/personal || true
      mkdir -p $HOME/github-repos/others/clone || true
      mkdir -p $HOME/github-repos/others/forks || true
      mkdir -p $HOME/github-repos/momentary || true
    '';
  };
}
