{
  # ---------------------------------------------------------------
  # 🖥️ HOST VARIABLES
  # ---------------------------------------------------------------

  hostname = "nixos-desktop";
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
  cosmic = false;

  # 📦 PACKAGES & TERMINAL
  flatpak = true;
  term = "kitty";

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
      wallpaperURL = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/os/nix-black-4k.png";
      wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
    }
    {
      wallpaperURL = "https://raw.githubusercontent.com/HyDE-Project/hyde-themes/Catppuccin-Mocha/Configs/.config/hyde/themes/Catppuccin%20Mocha/wallpapers/switch_swirl.jpg";
      wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
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
