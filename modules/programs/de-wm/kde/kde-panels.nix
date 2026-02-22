# Configure taskbar and panels using the community "plasma-manager" flake
{ delib
, lib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      primaryMonitorStr =
        if builtins.length myconfig.constants.monitors > 0 then
          builtins.elemAt myconfig.constants.monitors 0
        else
          "DP-1,1920x1080@60,0x0,1";
      monitorParts = lib.splitString "," primaryMonitorStr;
      resSection = builtins.elemAt monitorParts 1;
      dimSection = builtins.head (lib.splitString "@" resSection);
      heightStr = builtins.elemAt (lib.splitString "x" dimSection) 1;
      screenHeight = lib.toInt heightStr;
      panelHeight = builtins.floor (screenHeight * 2.5e-2);

      rawPinnedApps = cfg.pinnedApps;

      hasPins = builtins.length rawPinnedApps > 0;
      pinnedLaunchers = builtins.map (app: "applications:${app}") rawPinnedApps;
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
            {
              name = "org.kde.plasma.icontasks";
              config = lib.mkIf hasPins {
                General = {
                  launchers = pinnedLaunchers;
                };
              };
            }
            "org.kde.plasma.pager"
            "org.kde.plasma.panelspacer"
            "org.kde.plasma.systemtray"
            "org.kde.plasma.digitalclock"
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
    };
}
