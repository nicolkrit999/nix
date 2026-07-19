{
  hostname = "test-wallpaper-host";
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
  wallpapers = [
    {
      targetMonitor = "DP-1";
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Ros%C3%A9%20Pine/chainsaw_makima.png";
      wallpaperSHA256 = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
      gifURL = "";
      gifSHA256 = "";
    }
  ];
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
