{ delib, lib, ... }:
delib.module {
  name = "timezone";

  nixos.always =
    { myconfig, ... }:
    {
      time.timeZone = lib.mkDefault (myconfig.constants.timeZone or "Etc/UTC");
    };
}
