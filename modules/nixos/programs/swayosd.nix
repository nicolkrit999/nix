{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.swayosd";
  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    services.udev.packages = [ pkgs.swayosd ];
  };

  home.ifEnabled = { ... }: {
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
