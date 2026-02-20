{ delib, lib, ... }:
delib.module {
  name = "system.timezone";

  myconfig.always =
    { myconfig, ... }:
    {
      time.timeZone = lib.mkDefault (myconfig.constants.timeZone or "Etc/UTC");
    };
}
