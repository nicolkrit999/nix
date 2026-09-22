{ delib
, inputs
, ...
}:
delib.module {
  name = "krit.home.base";
  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }: {
    home.stateVersion = "25.11";
    home.username = myconfig.constants.user;
    home.homeDirectory = "/home/${myconfig.constants.user}";

    xdg.userDirs = { };

    home.activation.createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers || true
      mkdir -p $HOME/momentary || true
      mkdir -p $HOME/Music/shortwave || true
      mkdir -p $HOME/Music/miscellaneous ||true
      mkdir -p $HOME/.distrobox-bin || true
      mkdir -p $HOME/.config/portainer-mcp || true
      mkdir -p $HOME/github-repos/personal || true
      mkdir -p $HOME/github-repos/others/clone || true
      mkdir -p $HOME/github-repos/others/forks || true
      mkdir -p $HOME/github-repos/momentary || true
    '';
  };
}
