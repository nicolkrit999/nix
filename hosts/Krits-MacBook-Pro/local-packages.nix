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
        bc
        carbon-now-cli
        cloudflared
        fastfetch
        fd
        ffmpeg
        gh
        glow
        grex
        lsof
        mediainfo
        mars-mips
        ntfs3g
        pass
        pay-respects
        pokemon-colorscripts
        stow
        tree
        wakeonlan
        xcodegen
        zeal
        (pkgs.python313.withPackages (
          ps: with ps; [
            faker
          ]
        ))
        asciinema
        cbonsai
        neo-cowsay
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "uninstall";
        };

        taps = [ ];

        brews = [
          "node"
          "pipes-sh"
          #"direnv"
          "yt-dlp"
        ];

        casks = [
          "macfuse"
          "claude"
          "pycharm-ce"
          # "intellij-idea"
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
        ];
      };
    };
}
