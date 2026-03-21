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
          base16Theme = "nord";
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
      programs.bat.enable = true;
      programs.eza.enable = true;
      programs.git.enable = true;
      programs.lazygit.enable = true;
      programs.starship.enable = true;
      programs.tmux.enable = true;
      programs.television.enable = true;
      programs.zoxide.enable = true;
      programs.claude-code.enable = true;
      programs.shell-aliases.enable = true;

      stylix.enable = true;
      stylix.targets = {
        yazi.enable = false;
        kitty.enable = true;
        alacritty.enable = true;
        firefox.profileNames = [ "krit" ];
        librewolf.profileNames = [
          "default"
          "privacy"
        ];
      };

      home-packages.enable = true;



      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs.direnv.enable = true;
      krit.programs.neovim.enable = true;
      krit.programs.firefox.enable = true;
      krit.programs.librewolf.enable = false; # disabled: librewolf-148.0 fails to link on nixpkgs-25.11 (LLVM 21 vs 20 mismatch)
      krit.programs.chromium.enable = false;
      krit.programs.yazi.enable = true;
      krit.programs.ranger.enable = false;
      krit.programs.alacritty.enable = false;
      krit.programs.kitty.enable = true;

      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.nas.sshfs.enable = true;
      krit.services.nas.smb.enable = true;
      krit.services.nas.owncloud.enable = true;
      krit.services.nas.Krits-MacBook-Pro-borg-backup.enable = true;
      krit.services.Krits-MacBook-Pro.local-packages.enable = true;
      krit.services.Krits-MacBook-Pro.claude-code-wrappers.enable = true;

      # ---------------------------------------------------------------
      # 🍎 DARWIN-ONLY MODULES
      # ---------------------------------------------------------------
    };
}
