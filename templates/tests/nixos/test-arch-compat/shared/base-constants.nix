{
  hostname = "arch-compat-test";
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
  cachix = {
    enable = false;
    push = false;
    name = "krit-nixos";
    publicKey = "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks=";
  };
}
