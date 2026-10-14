{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.swayosd";
  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    services.udev.packages = [ pkgs.swayosd ];
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      caelestiaActiveOnHyprland =
        myconfig.programs.caelestia.enable
        && myconfig.programs.caelestia.enableOnHyprland
        && myconfig.programs.hyprland.enable;

      noctaliaActiveOnHyprland =
        myconfig.programs.noctalia.enable
        && myconfig.programs.noctalia.enableOnHyprland
        && myconfig.programs.hyprland.enable;

      noctaliaActiveOnNiri =
        myconfig.programs.noctalia.enable
        && myconfig.programs.noctalia.enableOnNiri
        && myconfig.programs.niri.enable;

      noctaliaActiveOnMango =
        myconfig.programs.noctalia.enable
        && myconfig.programs.noctalia.enableOnMango
        && myconfig.programs.mango.enable;

      hyprlandNeedsSwayosd =
        myconfig.programs.hyprland.enable
        && !caelestiaActiveOnHyprland
        && !noctaliaActiveOnHyprland;

      niriNeedsSwayosd =
        myconfig.programs.niri.enable
        && !noctaliaActiveOnNiri;

      mangoNeedsSwayosd =
        myconfig.programs.mango.enable
        && !noctaliaActiveOnMango;

      swayosdNeeded = hyprlandNeedsSwayosd || niriNeedsSwayosd || mangoNeedsSwayosd;
    in
    lib.mkIf swayosdNeeded {
      home.packages = [ pkgs.swayosd ];

      systemd.user.services.swayosd-server = {
        Unit = {
          Description = "SwayOSD Server";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment =
            lib.optional hyprlandNeedsSwayosd "|XDG_CURRENT_DESKTOP=Hyprland"
            ++ lib.optional niriNeedsSwayosd "|XDG_CURRENT_DESKTOP=niri"
            ++ lib.optional mangoNeedsSwayosd "|XDG_CURRENT_DESKTOP=mango";
        };
        Service = {
          ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
