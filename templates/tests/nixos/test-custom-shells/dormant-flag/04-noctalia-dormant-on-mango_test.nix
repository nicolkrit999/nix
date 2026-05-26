# D04 — Noctalia dormant on Mango (enable=false, enableOnMango=true)
# Expected: must behave exactly like P07 (no active shell).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./04-noctalia-dormant-on-mango;
  hm = H.getHm config;
  mangoBinds = hm.wayland.windowManager.mango.settings.bind;
in
nix-tests.runTests {
  "D04: noctalia dormant on mango — must behave as no-shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock IS installed — dormant shell must not disable it" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync IS installed — dormant enableOnMango must not suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "waybar-mango systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-mango");
    "SUPER+SHIFT,A is no-op (spawn true)" =
      helpers.isTrue (builtins.any (b: b == "SUPER+SHIFT,A,spawn,true") mangoBinds);
    "SUPER,Delete is loginctl not noctalia IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "loginctl lock-session" b) mangoBinds);
  };
}
