{ lib, vars, ... }:
{
  time.timeZone = lib.mkDefault "${vars.timeZone}";
}
