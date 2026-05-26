# P07 — Mango, no shell
# Expected: swaync + waybar present, bind dispatchers are no-op and loginctl.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./07-mango-no-shell;
  hm = H.getHm config;
  mangoBinds = hm.wayland.windowManager.mango.settings.bind;
in
nix-tests.runTests {
  "P07: mango, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync installed — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "waybar-mango systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-mango");
    "SUPER+SHIFT,A is a no-op (spawn true)" =
      helpers.isTrue (builtins.any (b: b == "SUPER+SHIFT,A,spawn,true") mangoBinds);
    "SUPER,Delete dispatches to loginctl lock-session" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "loginctl lock-session" b) mangoBinds);
  };
}
