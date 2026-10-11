# No wallpapers at all; catppuccin off so hyprlock builds its own background.
let base = import ./base-constants-static.nix;
in base // {
  wallpapers = [ ];
  theme = base.theme // { catppuccin = false; };
}
