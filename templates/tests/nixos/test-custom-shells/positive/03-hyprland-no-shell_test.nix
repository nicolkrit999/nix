# P03 — Hyprland, no shell
# Expected: swaync + wallpaper supervisor present, Super+Shift+A vicinae toggle, Super+Delete loginctl.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  inherit (H) lib;
  config = H.getConfig ./03-hyprland-no-shell;
  hm = H.getHm config;
in
nix-tests.runTests {
  "P03: hyprland, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "wallpaper supervisor started" =
      helpers.isTrue (lib.hasInfix "hyprland-wallpaperd" (H.hyprExecLua hm));
    "Super+Shift+A bind falls back to vicinae" =
      helpers.isEq (H.hyprBind hm "SUPER+SHIFT + A") ''SUPER+SHIFT + A hl.dsp.exec_cmd("vicinae toggle")'';
    "Super+Delete bind is loginctl lock-session" =
      helpers.isTrue (lib.hasInfix "loginctl lock-session" (H.hyprBind hm "SUPER + Delete"));
  };
}
