{ delib
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      optionalMs = value: {
        __type = "optional";
        inherit value;
      };
    in
    {
      wayland.desktopManager.cosmic.idle = {
        screen_off_time = optionalMs (myconfig.services.hypridle.screenOffTimeout * 1000);
        suspend_on_ac_time = optionalMs null;
        suspend_on_battery_time = optionalMs null;
      };
    };
}
