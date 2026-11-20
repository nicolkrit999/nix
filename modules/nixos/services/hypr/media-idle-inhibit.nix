{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "services.media-idle-inhibit";

  options = with delib; moduleOptions {
    enable = boolOption true;
    backend = lib.mkOption {
      type = lib.types.enum [ "dbus" "wayland" ];
      default = "dbus";
      description = "Inhibitor backend: dbus (org.freedesktop.ScreenSaver, served by hypridle or the compositor) or wayland (zwp_idle_inhibitor_v1).";
    };
    ryokuSession = boolOption false;
    mediaMinimumDuration = intOption 5;
    ignoredApps = listOfOption str [ ];
    sinkWhitelist = listOfOption str [ ];
  };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      wmEnabled = wm: myconfig.programs.${wm}.enable or false;
      isWmEnabled = wmEnabled "hyprland" || wmEnabled "niri" || wmEnabled "mango";
      ryokuActive = cfg.ryokuSession;
      wmTargets =
        lib.optional ryokuActive "ryoku-session.target"
        ++ lib.optional (wmEnabled "hyprland") "hyprland-session.target"
        ++ lib.optional (wmEnabled "niri") "niri.service"
        ++ lib.optional (wmEnabled "mango") "mango-session.target";

      configFile = (pkgs.formats.toml { }).generate "wayland-pipewire-idle-inhibit.toml" {
        media_minimum_duration = cfg.mediaMinimumDuration;
        idle_inhibitor = cfg.backend;
        sink_whitelist = map (name: { inherit name; }) cfg.sinkWhitelist;
        node_blacklist = map (name: { inherit name; }) cfg.ignoredApps;
      };
    in
    lib.mkIf (ryokuActive || (isWmEnabled && (myconfig.services.hypridle.enable or false))) {
      systemd.user.services.media-idle-inhibit = {
        Unit = {
          Description = "Inhibit idle while media is playing";
          PartOf = wmTargets;
          After = wmTargets ++ [ "pipewire.service" "hypridle.service" "ryoku-idle.service" ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.wayland-pipewire-idle-inhibit} --config ${configFile}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install.WantedBy = wmTargets;
      };
    };
}
