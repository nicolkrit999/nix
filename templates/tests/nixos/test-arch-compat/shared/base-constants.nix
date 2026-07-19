{
  hostname = "arch-compat-test";
  mainLocale = "en_US.UTF-8";
  lcTime = "";
  user = "krit";
  # Required since constants-nixos.nix removed the default: home-nixos.nix
  # reads this with no `or` fallback, so any host config (including this
  # test fixture) must set it explicitly. Matches nixos-desktop/nixos-laptop.
  homeStateVersion = "25.11";
  gitUserName = "Test User";
  gitUserEmail = "test@example.com";
  shell = "fish";
  browser = "zen-beta";
  editor = "nvim";
  fileManager = "yazi";
  terminal = {
    name = "kitty";
    cursorStyle = "block";
    cursorBlink = true;
    cursorBeamWidth = 3.0;
    animation = true;
  };
  screenshots = "$HOME/Pictures/Screenshots";
  keyboardLayout = "us";
  keyboardVariant = "";
  weather = "Lugano";
  useFahrenheit = false;
  nixImpure = false;
  timeZone = "Europe/Zurich";
  # wallpapers uses the default from constants-nixos.nix (non-empty); --dry-run never fetches.
  theme = {
    polarity = "dark";
    base16Theme = "catppuccin-mocha";
    catppuccin = true;
    catppuccinFlavor = "mocha";
    catppuccinAccent = "mauve";
  };
  hyprland = {
    rounding = 10;
    gap = 5;
    borderSize = 2;
    terminalOpacity = 0.9;
  };
  niri = {
    gap = 8;
    rounding = 10;
  };
}
