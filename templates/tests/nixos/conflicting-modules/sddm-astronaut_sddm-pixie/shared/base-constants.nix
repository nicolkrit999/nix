# Minimum constant set shared by every sddm-conflict test scenario.
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
    catppuccin = false;
    catppuccinFlavor = "mocha";
    catppuccinAccent = "mauve";
  };
}
