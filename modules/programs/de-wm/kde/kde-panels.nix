# Configure taskbar and panels using the community "plasma-manager" flake
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

      rawPinnedApps = cfg.pinnedApps;

      hasPins = builtins.length rawPinnedApps > 0;
      pinnedLaunchers = builtins.map (app: "applications:${app}") rawPinnedApps;
    in
    {
      programs.plasma.panels = [
        {
          screen = 0;
          location = "bottom";
          height = 44; # Default, change as needed
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
