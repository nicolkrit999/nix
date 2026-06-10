# Base constants for wallpaper tests that set both wallpaperURL and gifURL.
# Tests the gif-priority path: WMs use the GIF, DEs/stylix use the static URL.
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
      targetMonitor = "*";
      wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Ros%C3%A9%20Pine/chainsaw_makima.png";
      wallpaperSHA256 = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
      gifURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Pixel%20Dream/may_chill.gif";
      gifSHA256 = "1v3h995fifxcdvrizr5n99h0bmja7khzi89bh33d869psrjc4ssp";
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
  cachix = {
    enable = false;
    push = false;
    name = "krit-nixos";
    publicKey = "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks=";
  };
}
