# D02 — Caelestia dormant on Hyprland (enable=false, enableOnHyprland=true)
# Expected: must behave exactly like P03 (no active shell).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-caelestia-dormant-on-hyprland;
  hm = H.getHm config;
  binds = hm.wayland.windowManager.hyprland.settings.bind;
  execLua = (builtins.elemAt hm.wayland.windowManager.hyprland.settings.on._args 1).expr;
in
nix-tests.runTests {
  "D02: caelestia dormant on hyprland — must behave as no-shell" = helpers: {
    "no failing assertions — dormant shell must not trigger cross-shell assert" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock IS installed — dormant shell must not disable it" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync IS installed — dormant enableOnHyprland must not suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "awww wallpaper IS active — hyprlandFallback active" =
      helpers.isTrue (lib.hasInfix "awww-daemon" execLua);
    "waybar-hyprland systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-hyprland");
    "Super+Shift+A is no-op not caelestia IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix ''exec_cmd("true")'' (H.bindStr b)) binds);
    "Super+Delete is loginctl not caelestia IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "loginctl lock-session" (H.bindStr b)) binds);
  };
}
