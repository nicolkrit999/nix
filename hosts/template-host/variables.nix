{
  # ---------------------------------------------------------------
  # 🖥️ HOST VARIABLES
  # ---------------------------------------------------------------

  system = "x86_64-linux";

  # ⚙️ VERSIONS
  # During the first installation it is a good idea to make them the same as the other versions
  # Later where other version may be updated these 2 should not be changed, meaning they should remain what they were at the beginning
  # These 2 versions define where there system was created, and keeping them always the same it is a better idea
  stateVersion = "25.11";
  homeStateVersion = "25.11";

  # 👤 USER IDENTITY
  user = "template-user";
  gitUserName = "template-user";
  gitUserEmail = "template-user@example.com";

  # 🖥️ DESKTOP ENVIRONMENT
  hyprland = true;
  caelestia = false;

  gnome = false;
  kde = false;
  cosmic = false;

  # 📦 PACKAGES & TERMINAL
  flatpak = false;
  term = "alacritty";
  shell = "fish"; # Options: bash, zsh, fish

  # 📂 DEFAULT APPS
  browser = "firefox";
  editor = "code";
  fileManager = "dolphin";

  # 🎨 THEMING
  base16Theme = "nord";
  polarity = "dark";
  catppuccin = false;
  catppuccinFlavor = "mocha";
  catppuccinAccent = "sky";

  # ⚙️ SYSTEM SETTINGSS
  timeZone = "UTC";
  weather = "Greenwich";
  keyboardLayout = "us";
  keyboardVariant = "intl";

  screenshots = "$HOME/Pictures/screenshots";

  snapshots = false;

  # 💾 SNAPSHOT RETENTION POLICY
  snapshotRetention = {
    hourly = "24";
    daily = "7";
    weekly = "4";
    monthly = "3";
  };

  # 🛡️ SECURITY & NETWORKING
  tailscale = false;
  guest = false;
  zramPercent = 25;

  # 🖼️ MONITORS & WALLPAPERS
  monitors = [
  ];

  wallpapers = [
    {
      wallpaperURL = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/os/nix-black-4k.png";
      wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
    }
  ];

  # 🔋 POWER MANAGEMENT
  idleConfig = {
    enable = true;
    dimTimeout = 600;
    lockTimeout = 1800;
    screenOffTimeout = 3600;
    suspendTimeout = 7200;
  };
}
