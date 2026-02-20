{
  delib,
  lib,
  config,
  ...
}:
delib.module {
  name = "krit.programs.alacritty";
  options.krit.programs.alacritty = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { cfg, ... }:
    let
      enabledMonitors = builtins.filter (m: builtins.match ".*disable.*" m == null) constants.monitors;

      primaryMonitor = if builtins.length enabledMonitors > 0 then builtins.head enabledMonitors else "";
      parts = lib.splitString "," primaryMonitor;
      resolutionBlock = if builtins.length parts > 1 then builtins.elemAt parts 1 else "";
      widthList = lib.splitString "x" resolutionBlock;
      widthStr = if builtins.length widthList > 0 then builtins.head widthList else "";
      isNumber = builtins.match "[0-9]+" widthStr != null;
      width = if isNumber then lib.toInt widthStr else 1920;

      smartFontSize =
        if width > 3000 then
          16.0 # 4K
        else if width > 2000 then
          13.0 # 1440p
        else
          11.0;
    in
    {
      catppuccin.alacritty.enable = constants.theme.catppuccin or false;
      catppuccin.alacritty.flavor = constants.theme.catppuccinFlavor or "mocha";

      programs.alacritty = {
        enable = true;
        settings = {
          window.opacity = 1.0;
          font = {
            size = lib.mkForce smartFontSize;
            builtin_box_drawing = true;
            normal.style = lib.mkForce "Bold";
          };
        };
      };
    };
}
