{ delib, lib, ... }:
delib.module {
  name = "timezone";

  nixos.always =
    { constants, ... }:
    {
      time.timeZone = lib.mkDefault (constants.timeZone or "Etc/UTC");
    };
}
