{ lib, vars, ... }:
{
  time.timeZone = lib.mkDefault (vars.timeZone or "Etc/UTC");
}
