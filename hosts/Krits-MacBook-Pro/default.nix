{ delib, ... }:
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

        terminal.name = "kitty";
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

      programs = {
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
        claude-code.enable = false;
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

      home-packages.enable = true;

      krit.programs = {
        direnv.enable = true;
        neovim.enable = true;
        firefox.enable = true;
        librewolf.enable = false;
        chromium.enable = false;
        yazi.enable = true;
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
