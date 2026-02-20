{ delib, lib, ... }:
delib.module {
  name = "system.timezone";

  nixos.always =
    { nixos, ... }:
    {
      time.timeZone = lib.mkDefault (nixos.constants.timeZone or "Etc/UTC");
    };
}
