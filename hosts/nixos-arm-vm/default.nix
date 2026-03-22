{ delib
, ...
}:
let
  # Minimal let block - only what's actually needed for DE config
  myBrowser = "librewolf";
  myTerminal = "kitty";
  myEditor = "nvim";
  myFileManager = "yazi";
  isCatppuccin = true;

  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "chromium" = "chromium-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "yazi" = "yazi.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";
in

delib.host {
  name = "nixos-arm-vm";
  type = "ci-test";
  homeManagerSystem = "aarch64-linux";

  myconfig = { ... }: {
    # ---------------------------------------------------------------
    # 📦 CONSTANTS (Minimal for CI testing)
    # ---------------------------------------------------------------
    constants = {
      hostname = "nixos-arm-vm";
      mainLocale = "en_US.UTF-8";
      user = "krit";
      gitUserName = "Krit Pio Nicol";
      gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";
      terminal = myTerminal;
      shell = "fish";
      browser = myBrowser;
      editor = myEditor;
      fileManager = myFileManager;
      wallpapers = [
        {
          targetMonitor = "*";
          wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/AngelJumbo/gruvbox-wallpapers/gruvbox-wallpapers-main/wallpapers/brands/gruvbox-nix.png";
          wallpaperSHA256 = "18j302fdjfixi57qx8vgbg784ambfv9ir23mh11rqw46i43cdqjs";
        }
      ];
      theme = {
        polarity = "dark";
        base16Theme = "catppuccin-mocha";
        catppuccin = true;
        catppuccinFlavor = "mocha";
        catppuccinAccent = "teal";
      };
      screenshots = "$HOME/Pictures/Screenshots";
      keyboardLayout = "us";
      keyboardVariant = "";
      weather = "Lugano";
      useFahrenheit = false;
      nixImpure = false;
      timeZone = "Europe/Zurich";
    };

    # ---------------------------------------------------------------
    # 🌐 TOP-LEVEL MODULES (Test ARM compatibility)
    # ---------------------------------------------------------------
    bluetooth.enable = true;
    cachix.enable = true;
    guest.enable = true;
    home-packages.enable = true;
    mime.enable = true;
    nh.enable = true;
    qt.enable = true;
    zram.enable = true;

    stylix = {
      enable = true;
      targets = {
        yazi.enable = false;
        cava.enable = true;
        kitty.enable = !isCatppuccin;
        alacritty.enable = !isCatppuccin;
        zathura.enable = !isCatppuccin;
        firefox.profileNames = [ "krit" ];
        librewolf.profileNames = [ "default" "privacy" ];
      };
    };

    # ---------------------------------------------------------------
    # 🚀 PROGRAMS (Test ARM compatibility)
    # ---------------------------------------------------------------
    programs = {
      bat.enable = true;
      eza.enable = true;
      fzf.enable = true;
      git.enable = true;
      lazygit.enable = true;
      shell-aliases.enable = true;
      starship.enable = true;
      tmux.enable = true;
      walker.enable = true;
      waybar.enable = true;
      zoxide.enable = true;
      caelestia.enable = true;
      noctalia.enable = true;
      hyprland.enable = true;
      niri.enable = true;
      gnome = {
        enable = true;
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
        ];
      };
      cosmic.enable = true;
      kde = {
        enable = true;
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
        ];
      };
    };

    # ---------------------------------------------------------------
    # ⚙️ SERVICES (Test ARM compatibility)
    # ---------------------------------------------------------------
    services = {
      audio.enable = true;
      hyprlock.enable = true;
      sddm.enable = true;
      impermanence.enable = true;
      tailscale.enable = true;
      snapshots.enable = true;
      hypridle.enable = true;
      swaync.enable = true;
    };

    # ---------------------------------------------------------------
    # 👤 KRIT PROGRAMS (Test ARM compatibility)
    # ---------------------------------------------------------------
    krit.programs = {
      alacritty.enable = true;
      kitty.enable = true;
      cava.enable = true;
      chromium.enable = true;
      direnv.enable = true;
      dolphin.enable = true;
      firefox.enable = true;
      librewolf.enable = true;
      neovim.enable = true;
      pwas.enable = true;
      ranger.enable = true;
      yazi.enable = true;
      zathura.enable = true;
    };

    # ---------------------------------------------------------------
    # 👤 KRIT SERVICES
    # ---------------------------------------------------------------
    krit.services.logitech.enable = true;
    # NAS services disabled - require sops secrets

    # ---------------------------------------------------------------
    # 🔧 KRIT SYSTEM (except sops-dependent)
    # ---------------------------------------------------------------
    krit.system = {
      swiss-locale.enable = true;
      # git-ssh-signing disabled - requires SSH keys from sops
      # default-user disabled - using initialPassword for CI
      virtualisation.enable = true;
      resolved.enable = true;
      autotrash.enable = true;
    };

    # ---------------------------------------------------------------
    # 🏠 KRIT HOME
    # ---------------------------------------------------------------
    krit.home.base.enable = true;
  };
}
