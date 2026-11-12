{ lib, ... }:
let
  sink = path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkOption {
    type = lib.types.bool;
    default = true;
  });
in
{
  options = lib.foldl' lib.recursiveUpdate { } (map sink [
    [ "programs" "cosmic" ]
    [ "programs" "gnome" ]
    [ "programs" "hyprland" ]
    [ "programs" "kde" ]
    [ "programs" "mango" ]
    [ "programs" "niri" ]
    [ "programs" "caelestia" ]
    [ "programs" "noctalia" ]
    [ "programs" "skwdWall" ]
    [ "programs" "vicinae" ]
    [ "programs" "walker" ]
    [ "programs" "swayosd" ]
    [ "programs" "waybar-hyprland" ]
    [ "programs" "waybar-mango" ]
    [ "programs" "waybar-niri" ]
    [ "programs" "fastfetch" ]
    [ "programs" "starship" ]
    [ "services" "auto-cpufreq" ]
    [ "services" "coffee" ]
    [ "services" "hypridle" ]
    [ "services" "sddm-astronaut" ]
    [ "services" "sddm-pixie" ]
    [ "services" "swaync" ]
    [ "services" "tlp" ]
    [ "qt" ]
    [ "bluetooth" ]
  ]);
}
