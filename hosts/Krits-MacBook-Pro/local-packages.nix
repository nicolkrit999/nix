{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.Krits-MacBook-Pro.local-packages";
  options = delib.singleEnableOption false;
  darwin.ifEnabled =
    { ... }:
    {
      environment.systemPackages = with pkgs; [
        # CLI tools
        asciinema
        carbon-now-cli
        cbonsai
        cloudflared
        fd
        ffmpeg
        gh
        grex
        htop
        inetutils
        lsof
        mediainfo
        neo-cowsay
        nix-search-cli
        ntfs3g
        pay-respects
        ripgrep
        stow
        tree
        unzip
        upterm
        wakeonlan
        yt-dlp
        zip
        zlib

        # Development
        mars-mips
        vscode
        xcodegen
        (pkgs.python313.withPackages (
          ps: with ps; [
            faker
          ]
        ))

        # Apps
        notion-app
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = false;
          cleanup = "none";
        };

        brews = [
          "direnv"
          "node"
          "pipes-sh"
        ];

        casks = [
          # Apps
          "claude"
          "dash"
          "discord"
          "github"
          "iterm2"
          "microsoft-teams"
          "obs"
          "openlogi"
          "only-switch"
          "pearcleaner"
          "pycharm"
          "signal"
          "tailscale-app"
          "telegram"
          "utm"
          "vlc"

          # System
          "font-jetbrains-mono-nerd-font"
          "macfuse"
        ];
      };
    };
}
