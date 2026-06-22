{ delib, pkgs, ... }:
delib.host {
  name = "Krits-MacBook-Pro";
  type = "desktop";

  homeManagerSystem = "aarch64-darwin";

  myconfig =
    { ... }:
    {
      constants = {
        hostname = "Krits-MacBook-Pro";
        user = "krit";
        uid = 501;

        terminal.name = "alacritty";
        shell = "fish";
        browser = "firefox";
        editor = "nvim";
        fileManager = "yazi";

        darwinStateVersion = 4;
        homeStateVersion = "25.11";

        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        theme = {
          polarity = "dark";
          base16Theme = "gruvbox-material-dark-soft";
          catppuccin = false;
          catppuccinFlavor = "macchiato";
          catppuccinAccent = "mauve";
        };
      };

      cachix = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/cachix-push-token";
      };

      krit.attic = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/attic-push-token";
      };

      krit.commonSopsSecrets.enable = true;

      programs = {
        nltchNur = {
          enable = true;
          packages = [ ];
          permittedInsecurePackages = [ ];
        };

        bat.enable = true;
        eza.enable = true;
        statix.enable = true;
        comma.enable = true;
        git.enable = true;
        lazygit.enable = true;
        starship.enable = true;
        tmux.enable = true;
        fzf.enable = true;
        fzf.nix-search-tv.enable = true;
        television.enable = true;
        zoxide.enable = true;
        headroom.enable = true;
        claude-code.enable = true;
        npm = {
          enable = true;
          packages = [
            "claudefm"
            "claude-token-counter"
          ];
          hostPackages = with pkgs; [
            yt-dlp
            mpv
          ];
        };
        shell-aliases.enable = true;
      };

      stylix = {
        enable = true;
        targets = {
          yazi.enable = false;
          kitty.enable = true;
          alacritty.enable = true;
          firefox.profileNames = [ "krit" ];
          librewolf.profileNames = [
            "default"
            "privacy"
          ];
        };
      };

      nh = {
        enable = true;
        gcd = "30d";
        gcn = "10";
      };
      nix-sweeps = {
        enable = true;
        gcd = "30d";
        gcn = "10";
      };

      home-packages.enable = true;

      krit.programs = {
        direnv.enable = false;
        neovim.enable = true;
        firefox.enable = true;
        librewolf.enable = false;
        chromium.enable = false;
        yazi.enable = true;
        proton-cli.enable = true;
        ranger.enable = false;
        claude-code-wrappers.enable = true;
        alacritty.enable = false;

        kitty = {
          enable = true;
          fontSize = 14;
        };
      };

      krit.services.nas = {
        Krits-MacBook-Pro-borg-backup.enable = true;
        owncloud.enable = false;
        smb.enable = true;
        sshfs.enable = false;
      };

      krit.services.Krits-MacBook-Pro = {
        local-packages.enable = true;
      };

      darwin.services.external = {
        dotfiles.enable = true;
        dotfiles-private.enable = true;
      };


      # ---------------------------------------------------------------
      # 🍎 DARWIN-ONLY MODULES
      # ---------------------------------------------------------------
      krit.home.base.enable = true;

      krit.system = {
        git-ssh-signing.enable = true;
        ssh-config.enable = true;
      };
    };
}
