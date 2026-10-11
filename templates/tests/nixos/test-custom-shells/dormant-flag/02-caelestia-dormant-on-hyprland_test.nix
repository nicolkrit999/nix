# D02 — Caelestia on Hyprland dormant (enable=false, enableOnX=true)
# Expected: config identical to the matching no-shell positive scenario.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-caelestia-dormant-on-hyprland;
  hm = H.getHm config;
  control = H.getHm (H.getConfig ../positive/03-hyprland-no-shell);
  snap = h: {
    swaync = h.services.swaync.enable;
    execLua = H.hyprExecLua h;
    launcher = H.hyprBind h "SUPER+SHIFT + A";
    lock = H.hyprBind h "SUPER + Delete";
    binds = map H.bindStr h.wayland.windowManager.hyprland.settings.bind;
  };
in
nix-tests.runTests {
  "D02: caelestia dormant on hyprland — must behave as no-shell" = helpers: {
    "no failing assertions — dormant shell must not trigger cross-shell assert" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — dormant flag must not suppress it" =
      helpers.isTrue (snap hm).swaync;
    "binds and startup identical to the no-shell scenario" =
      helpers.isEq (snap hm) (snap control);
    "Super+Shift+A bind is the no-op, not the shell IPC" =
      helpers.isEq (snap hm).launcher ''SUPER+SHIFT + A hl.dsp.exec_cmd("true")'';
    "Super+Delete bind is loginctl lock-session" =
      helpers.isTrue (lib.hasInfix "loginctl lock-session" (snap hm).lock);
  };
}
