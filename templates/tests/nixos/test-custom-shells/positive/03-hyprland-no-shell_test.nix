# P03 — Hyprland, no shell
# No custom shell active. Expected: swaync + hyprpaper + waybar all present,
# bind dispatchers are no-op (Super+Shift+A) and loginctl (Super+Delete).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./03-hyprland-no-shell;
  hm = H.getHm config;
  binds = hm.wayland.windowManager.hyprland.settings.bind;
in
nix-tests.runTests {
  "P03: hyprland, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync installed — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "hyprpaper installed — hyprlandFallback active" =
      helpers.isTrue hm.services.hyprpaper.enable;
    "waybar-hyprland systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-hyprland");
    "Super+Shift+A is a no-op (no shell active)" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "exec, true" b) binds);
    "Super+Delete dispatches to loginctl lock-session" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "loginctl lock-session" b) binds);
  };
}
