{
  # ---------------------------------------------------------------
  # 🖥️ HOST VARIABLES
  # ---------------------------------------------------------------

  system = "aarch64-linux";

  # ⚙️ VERSIONS
  # During the first installation it is a good idea to make them the same as the other versions
  # Later where other version may be updated these 2 should not be changed, meaning they should remain what they were at the beginning
  # These 2 versions define where there system was created, and keeping them always the same it is a better idea
  stateVersion = "25.11";
  homeStateVersion = "25.11";

  # 👤 USER IDENTITY
  user = "krit";
  gitUserName = "nicolkrit999";
  gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

  # 🖥️ DESKTOP ENVIRONMENT & WINDOW MANAGER
  hyprland = true;
  niri = true;

  gnome = true;
  kde = true;
  cosmic = true;

  # 🐚 SHELLS & BARS
  # Control which bar/shell to use for each Window Manager.
  # If all are false for a WM, it falls back to Waybar.

  # Hyprland Options
  # These 2 should not be true at the same time
  hyprlandCaelestia = false; # Enable Caelestia for Hyprland
  hyprlandNoctalia = true; # Enable Noctalia for Hyprland

  # Niri Options
  niriNoctalia = true; # Enable Noctalia for Niri (No Caelestia support on Niri)

  # 📦 PACKAGES & TERMINAL
  flatpak = true;
  term = "kitty";
  shell = "fish"; # Options: bash, zsh, fish

  # 📂 DEFAULT APPS
  browser = "firefox";
  editor = "nvim";
  fileManager = "yazi";

  # 🎨 THEMING
  base16Theme = "nord";
  polarity = "dark";
  catppuccin = false;
  catppuccinFlavor = "mocha";
  catppuccinAccent = "mauve";

  # ⚙️ SYSTEM SETTINGS
  timeZone = "Europe/Zurich";
  weather = "Lugano";
  keyboardLayout = "us,it,de,fr";
  keyboardVariant = "intl,,,";

  screenshots = "$HOME/Pictures/screenshots";

  snapshots = true;

  # 💾 SNAPSHOT RETENTION POLICY
  snapshotRetention = {
    hourly = "24";
    daily = "7";
    weekly = "4";
    monthly = "3";
    yearly = "2";
  };

  # 🛡️ SECURITY & NETWORKING
  tailscale = true;
  guest = true;
  zramPercent = 50; # Increased to improve battery life

  # 🖼️ MONITORS & WALLPAPERS
  monitors = [
    "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
    "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"
    "HDMI-A-1,disable"
  ];

  wallpapers = [
    {
      wallpaperURL =
        "https://raw.githubusercontent.com/nicolkrit999/wallpaper-repo/main/various/various-websites/wallhaven/wallhaven-anime-girl-drink-4k-grey.png";
      wallpaperSHA256 = "0q5j531m3a1x5x99d0xybcb9rgc7w1i3v2vgf81zpwcwqj7abnzr";
    }

    {
      wallpaperURL =
        "https://raw.githubusercontent.com/nicolkrit999/wallpaper-repo/main/various/other-user-github-repos/JoydeepMallick/Wallpapers/a_black_and_white_logo.png";
      wallpaperSHA256 = "1q0p9sq40lq9b3icncq8a223v5yk33w4nz3pymwz2gwv3psjzzw1";
    }
  ];

  # 🔋 POWER MANAGEMENT
  idleConfig = {
    enable = true;
    dimTimeout = 300;
    lockTimeout = 900;
    screenOffTimeout = 1200;
    suspendTimeout = 1800;
  };

  devLanguages = [
    # Development environments configurations.
    # If a module is enabled their respective packages are installed permanently
    # To use them it's needed to add a .envrc file in the project folder that link to the dev-environment
    #"c-cpp"
    #"go"
    #"haskell"
    #"java"
    #"jupyter"
    #"latex"
    "nix"
    #"node"
    #"php"
    #"python"
    #"r"
    #"rust"
    "shell"
    #"swift"
    "typst"
  ];
}
