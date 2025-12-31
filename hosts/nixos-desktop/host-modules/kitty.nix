{
  lib,
  pkgs,
  monitors,
  catppuccin,
  catppuccinFlavor,
  term,
  ...
}:

let
  enabledMonitors = builtins.filter (m: builtins.match ".*disable.*" m == null) monitors;
  # Get primary monitor
  primaryMonitor = if builtins.length enabledMonitors > 0 then builtins.head enabledMonitors else "";
  # Extract width (Handle empty string)
  parts = lib.splitString "," primaryMonitor;
  resolutionBlock = if builtins.length parts > 1 then builtins.elemAt parts 1 else "";
  # Get Width String
  widthList = lib.splitString "x" resolutionBlock;
  widthStr = if builtins.length widthList > 0 then builtins.head widthList else "";
  # Convert to integer (Default to 1920 if fails)
  isNumber = builtins.match "[0-9]+" widthStr != null;
  width = if isNumber then lib.toInt widthStr else 1920;

  # Determine Font Size
  smartFontSize =
    if width > 3000 then
      16.0 # 4K
    else if width > 2000 then
      13.0 # 1440p
    else
      11.0;
  # 1080p

in
{
  catppuccin.kitty.enable = catppuccin;
  catppuccin.kitty.flavor = catppuccinFlavor;

  programs.kitty = {
    enable = true;

    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = lib.mkForce smartFontSize;

      background_opacity = lib.mkForce "1.0";

      copy_on_select = "yes"; # automatically copy selected text to clipboard

      window_padding_width = 4;

      confirm_os_window_close = 0; # 0 = don't ask, 1 = ask

      enable_audio_bell = false;

      mouse_hide_wait = "3.0"; # seconds of inactivity before hiding mouse cursor
    };
  };
}
