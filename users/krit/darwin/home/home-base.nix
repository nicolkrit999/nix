{ delib
, inputs
, ...
}:
delib.module {
  name = "krit.home.base";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    {
      home.stateVersion = "25.11";
      home.username = myconfig.constants.user;
      home.homeDirectory = "/Users/${myconfig.constants.user}";

      home.sessionVariables = {
        EDITOR = myconfig.constants.editor;
        VISUAL = myconfig.constants.editor;
      };

      home.activation = {
        createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/Pictures/wallpapers || true
          mkdir -p $HOME/momentary || true
          mkdir -p $HOME/.config/portainer-mcp || true
        '';
      };
    };
}
