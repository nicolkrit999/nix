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
  user = "krit";
  gitUserName = "nicolkrit999";
  gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

  # 🖥️ DESKTOP ENVIRONMENT
  hyprland = true;
  gnome = true;
  kde = true;
  cosmic = true;
  caelestia = true;

  # 📦 PACKAGES & TERMINAL
  flatpak = true;
  term = "kitty";

  # 📂 DEFAULT APPS
  browser = "firefox";
  editor = "code";
  fileManager = "dolphin";

  # 🎨 THEMING
  base16Theme = "kanagawa-dragon";
  polarity = "dark";
  catppuccin = false;
  catppuccinFlavor = "mocha";
  catppuccinAccent = "sky";

  # ⚙️ SYSTEM SETTINGS
  timeZone = "Europe/Zurich";
  weather = "Lugano";
  keyboardLayout = "us,ch,de,fr,it";
  keyboardVariant = "intl,,,,";

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
  zramPercent = 25;

  # 🖼️ MONITORS & WALLPAPERS
  monitors = [
    "DP-1,3840x2160@240,1440x560,1.5"
    "DP-2,3840x2160@144,0x0,1.5,transform,1"
    "HDMI-A-1,disable"
  ];

  wallpapers = [
    {
      wallpaperURL = "https://w.wallhaven.cc/full/7j/wallhaven-7jjo5e.jpg";
      wallpaperSHA256 = "1lbva41v68hns6pkksb0v7yhwckhgfvrg9s1nrp76qkqg54pcv70";
    }
    {
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/nixOS/develop/wallpapers/phili-pilz-portrait-deer.jpg";
      wallpaperSHA256 = "0fwbas4658d0dgrnx890if2ang70hilzsnw9zydda4n5cbhlfxhx";
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
