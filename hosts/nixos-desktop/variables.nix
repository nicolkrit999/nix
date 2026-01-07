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
  caelestia = true;

  gnome = true;
  kde = true;
  cosmic = true;

  # 📦 PACKAGES & TERMINAL
  flatpak = true;
  term = "kitty";

  # 📂 DEFAULT APPS
  browser = "firefox";
  editor = "nvim";
  fileManager = "yazi";

  # 🎨 THEMING
  base16Theme = "catppuccin-mocha";
  polarity = "dark";
  catppuccin = true;
  catppuccinFlavor = "mocha";
  catppuccinAccent = "mauve";

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
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/nixOS/main/wallpapers/other-user-github-repos/D3Ext/aesthetic-wallpapers/black-white-girl.png";
      wallpaperSHA256 = "0q5j531m3a1x5x99d0xybcb9rgc7w1i3v2vgf81zpwcwqj7abnzr";
    }
    {
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/nixOS/develop/wallpapers/various/mudassir-ali_pixelcop.jpg";
      wallpaperSHA256 = "00zblsr0w0scdbz8fy7i6r97pcgnyb8hmy5gyq94cg555sd2zf9q";
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
