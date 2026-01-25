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
  # FIXME: They need gpu-screen-recorder to work, which is not supported on aarch64
  hyprlandCaelestia = false; # Enable Caelestia for Hyprland
  hyprlandNoctalia = false; # Enable Noctalia for Hyprland

  # Niri Options
  # FIXME: They need gpu-screen-recorder to work, which is not supported on aarch64
  niriNoctalia = false; # Enable Noctalia for Niri (No Caelestia support on Niri)

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
  monitors = [ "Virtual-1, 1920x1080@60, 0x0, 1" ];

  wallpapers = [
    {
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/dotfiles/main/wallpaper-repo/Pictures/wallpapers/various/various-websites/wallhaven/wallhaven-anime-girl-drink-4k-grey.png";
      wallpaperSHA256 = "0q5j531m3a1x5x99d0xybcb9rgc7w1i3v2vgf81zpwcwqj7abnzr";
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

  useCases = [
    #"gaming"
  ];

  # Cachix
  cachix = {
    enable = true;
    push = false; # Only the builder must have this true (for now "nixos-desktop")
    name = "krit-nixos";
    publicKey = "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks=";
  };
}
