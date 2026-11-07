{ original, luks ? false }:
{ cloneHardware ? false, ... }:
{
  imports = [
    (if cloneHardware then import ./generic-hardware.nix { inherit luks; } else original)
  ];
}
