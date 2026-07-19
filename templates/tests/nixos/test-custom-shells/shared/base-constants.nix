# Minimum constant set shared by every test scenario.
# catppuccin = true so catppuccin flake options (e.g. hyprland accent) are enabled.
# wallpapers = [] to avoid network fetches (stylix image not needed for eval).
{
  hostname = "test-fake-host";
  mainLocale = "en_US.UTF-8";
  lcTime = "";
  user = "krit";
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
  wallpapers = [ ];
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
