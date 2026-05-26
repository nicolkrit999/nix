# D03 — Noctalia dormant on Niri (enable=false, enableOnNiri=true)
# Expected: must behave exactly like P05 (no active shell).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./03-noctalia-dormant-on-niri;
  hm = H.getHm config;
  niriBinds = hm.programs.niri.settings.binds;
  launcherSpawn = niriBinds."Mod+Shift+A".action.spawn;
  lockSpawn = niriBinds."Mod+Delete".action.spawn;
in
nix-tests.runTests {
  "D03: noctalia dormant on niri — must behave as no-shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock IS installed — dormant shell must not disable it" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync IS installed — dormant enableOnNiri must not suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "waybar-niri systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-niri");
    "Mod+Shift+A is no-op (spawn true)" =
      helpers.isEq launcherSpawn [ "true" ];
    "Mod+Delete is loginctl not noctalia IPC" =
      helpers.isEq lockSpawn [ "loginctl" "lock-session" ];
  };
}
