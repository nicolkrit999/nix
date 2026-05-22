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
        fastfetch
        fd
        gh
        htop
        inetutils
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
