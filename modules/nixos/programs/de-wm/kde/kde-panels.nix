{ delib
, lib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg
    , ...
    }:
    let
      pinnedLaunchers = builtins.map (app: "applications:${app}") cfg.pinnedApps;

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
          config = lib.mkIf (cfg.pinnedApps != [ ]) {
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
    in
    {
      programs.plasma.panels = [
        {
          screen = "all";
          location = "bottom";
          height = 44;
          floating = false;
          hiding = "autohide";

          inherit widgets;
        }
      ];
    };
}
