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
        notion-app
        carbon-now-cli
        cloudflared
        fastfetch
        fd
        ffmpeg
        gh
        grex
        htop
        inetutils
        lsof
        mediainfo
        mars-mips
        nix-search-cli
        ntfs3g
        pay-respects
        pokemon-colorscripts
        ripgrep
        stow
        tmate
        tree
        unzip
        vscode
        wakeonlan
        xcodegen
        yt-dlp
        zip
        zlib
        (pkgs.python313.withPackages (
          ps: with ps; [
            faker
          ]
        ))
        asciinema
        cbonsai
        neo-cowsay
        iperf3 # Network bandwidth testing tool
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = false;
          cleanup = "none";
        };

        taps = [ ];

        brews = [
          "node"
          "pipes-sh"
          "direnv"
          "yt-dlp"
        ];

        casks = [
          "macfuse"
          "claude"
          "pycharm-ce"
          "alacritty"
          "discord"
          "iterm2"
          "pearcleaner"
          "only-switch"
          "font-jetbrains-mono-nerd-font"
          "obs"
          "utm"
          "tailscale-app"
          "telegram"
          "microsoft-teams"
          "signal"
          "vlc"
          "github"
          "dash"
        ];
      };
    };
}
