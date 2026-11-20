{ delib
, lib
, ...
}:
let
  sessions = [ "hyprland" "niri" "mango" "gnome" "kde" "cosmic" ];
  isSessionEnabled = myconfig: lib.any (s: myconfig.programs.${s}.enable or false) sessions;
in
delib.module {
  name = "services.powerKeyLock";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
  };

  nixos.ifEnabled = { myconfig, ... }:
    lib.mkIf (isSessionEnabled myconfig) {
      services.logind.settings.Login = {
        HandlePowerKey = "lock";
        HandlePowerKeyLongPress = "poweroff";
      };
    };
}
