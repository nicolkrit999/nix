{
  config,
  lib,
  monitors,
  ...
}:

let
  primaryMonitorStr =
    if builtins.length monitors > 0 then builtins.elemAt monitors 0 else "DP-1,1920x1080@60,0x0,1";
  monitorParts = lib.splitString "," primaryMonitorStr;
  resSection = builtins.elemAt monitorParts 1;
  dimSection = builtins.head (lib.splitString "@" resSection);
  heightStr = builtins.elemAt (lib.splitString "x" dimSection) 1;
  screenHeight = lib.toInt heightStr;
  panelHeight = builtins.floor (screenHeight * 0.025);
in
{
  programs.plasma.panels = [
    {
      screen = 0;
      location = "bottom";
      height = panelHeight;

      floating = false;

      hiding = "autohide";

      widgets = [
        {
          name = "org.kde.plasma.kickoff";
          config = {
            General = {
              icon = "nix-snowflake-white";
              alphaSort = true;
            };
          };
        }
        "org.kde.plasma.pager"
        "org.kde.plasma.icontasks"
        "org.kde.plasma.panelspacer"
        "org.kde.plasma.systemtray"
        "org.kde.plasma.digitalclock"
        "org.kde.plasma.showdesktop"
      ];
    }
  ];
}
