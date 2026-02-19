{ delib, lib, ... }:
delib.module {
  name = "system.timezone";

  nixos.always =
    { myconfig, ... }:
    {
      time.timeZone = lib.mkDefault (myconfig.constants.timeZone or "Etc/UTC");
    };
}
