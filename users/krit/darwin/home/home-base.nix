{ delib
, inputs
, pkgs
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

      home.packages = with pkgs; [
        vscode
        ranger
        killall
        nix-search-cli
        ripgrep
        unzip
        zip
        zlib
        wget
      ];

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
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
