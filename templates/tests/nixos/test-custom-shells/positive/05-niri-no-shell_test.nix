# P05 — Niri, no shell
# Expected: swaync + waybar present, bind dispatchers are no-op and loginctl.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./05-niri-no-shell;
  hm = H.getHm config;
  niriBinds = hm.programs.niri.settings.binds;
  launcherSpawn = niriBinds."Mod+Shift+A".action.spawn;
  lockSpawn = niriBinds."Mod+Delete".action.spawn;
in
nix-tests.runTests {
  "P05: niri, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync installed — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "waybar-niri systemd service present" =
      helpers.isTrue (hm.systemd.user.services ? "waybar-niri");
    "Mod+Shift+A is a no-op (spawn true)" =
      helpers.isEq launcherSpawn [ "true" ];
    "Mod+Delete dispatches to loginctl lock-session" =
      helpers.isEq lockSpawn [ "loginctl" "lock-session" ];
  };
}
