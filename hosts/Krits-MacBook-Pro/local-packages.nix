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
      ];

      homebrew = {
        enable = true;
        # Keep Homebrew deterministic: only ensure the listed packages exist.
        # autoUpdate/upgrade pulled bleeding-edge Homebrew + mas that outran
        # nix-darwin (broke `brew bundle` MAS support and deprecated the
        # `--cleanup` flag that "uninstall"/"zap" rely on). Run `brew update`,
        # `brew upgrade`, and `brew bundle cleanup --force` manually when wanted.
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
