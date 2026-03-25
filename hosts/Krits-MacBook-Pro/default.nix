{ delib, ... }:
delib.host {
  name = "Krits-MacBook-Pro";
  type = "desktop";

  homeManagerSystem = "aarch64-darwin";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK
      # ---------------------------------------------------------------
      constants = {
        hostname = "Krits-MacBook-Pro";
        user = "krit";
        uid = 501;

        terminal = "kitty";
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

      # ---------------------------------------------------------------
      # 🌐 SHARED MODULES
      # Note: fish/zsh auto-enable based on constants.shell
      # Note: kitty is configured via krit.programs.kitty below
      # ---------------------------------------------------------------
      programs = {
        bat.enable = true;
        eza.enable = true;
        statix.enable = true;
        comma.enable = true;
        git.enable = true;
        lazygit.enable = true;
        starship.enable = true;
        tmux.enable = true;
        television.enable = true;
        zoxide.enable = true;
        claude-code.enable = true;
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

      home-packages.enable = true;



      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs = {
        direnv.enable = false;
        neovim.enable = true;
        firefox.enable = true;
        librewolf.enable = false; # disabled: librewolf-148.0 fails
        chromium.enable = false;
        yazi.enable = true;
        ranger.enable = false;
        alacritty.enable = false;

        kitty = {
          enable = true;
          fontSize = 14;
        };
      };



      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------


      krit.services.nas = {
        Krits-MacBook-Pro-borg-backup.enable = true;
        owncloud.enable = false;
        smb.enable = true;
        sshfs.enable = false;
      };

      krit.services.Krits-MacBook-Pro.local-packages.enable = true;

      krit.programs.claude-code-wrappers.enable = true;

      # ---------------------------------------------------------------
      # 🍎 DARWIN-ONLY MODULES
      # ---------------------------------------------------------------
      krit.home.base.enable = true;
      krit.system.git-ssh-signing.enable = true;
      krit.system.ssh-config.enable = true;
    };
}
