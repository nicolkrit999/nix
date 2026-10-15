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

    home.activation.createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p \
        "$HOME/Pictures/wallpapers" \
        "$HOME/momentary" \
        "$HOME/Music/shortwave" \
        "$HOME/Music/miscellaneous" \
        "$HOME/.config/portainer-mcp" \
        "$HOME/github-repos/personal" \
        "$HOME/github-repos/others/clone" \
        "$HOME/github-repos/others/forks" \
        "$HOME/github-repos/momentary" || true
    '';
  };
}
