{ delib, lib, ... }:
delib.module {
  name = "timezone";

  nixos.always =
    { cfg, myconfig, ... }:
    {
      time.timeZone = lib.mkDefault (myconfig.constants.timeZone or "Etc/UTC");
    };
}
