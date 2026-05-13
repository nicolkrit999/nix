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
      # Three-way active checks — dormant per-WM flags alone must NOT suppress
      # swayosd; all three conditions (master + per-WM + wm.enable) are required.
      caelestiaActiveOnHyprland =
        (myconfig.programs.caelestia.enable or false)
        && (myconfig.programs.caelestia.enableOnHyprland or false)
        && (myconfig.programs.hyprland.enable or false);

      noctaliaActiveOnHyprland =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnHyprland or false)
        && (myconfig.programs.hyprland.enable or false);

      noctaliaActiveOnNiri =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnNiri or false)
        && (myconfig.programs.niri.enable or false);

      noctaliaActiveOnMango =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnMango or false)
        && (myconfig.programs.mango.enable or false);

      # swayosd is needed when at least one active WM has no shell providing
      # its own OSD. Shells suppress it only on the specific WM they run on.
      hyprlandNeedsSwayosd =
        (myconfig.programs.hyprland.enable or false)
        && !caelestiaActiveOnHyprland
        && !noctaliaActiveOnHyprland;

      niriNeedsSwayosd =
        (myconfig.programs.niri.enable or false)
        && !noctaliaActiveOnNiri;

      mangoNeedsSwayosd =
        (myconfig.programs.mango.enable or false)
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
