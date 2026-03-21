{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.Krits-MacBook-Pro.local-packages";

  options.krit.services.Krits-MacBook-Pro.local-packages = with delib; {
    enable = boolOption false;
  };

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
        ntfs3g
        pass
        pay-respects
        pokemon-colorscripts
        stow
        tree
        yt-dlp
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
        ];

        casks = [
          "macfuse"
          "claude"
          "pycharm-ce"
          "intellij-idea-ce"
          "alacritty"
          "discord"
          "iterm2"
          "pearcleaner"
          "only-switch"
          "font-jetbrains-mono-nerd-font"
          "obs"
          "utm"
          "firefox"
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
