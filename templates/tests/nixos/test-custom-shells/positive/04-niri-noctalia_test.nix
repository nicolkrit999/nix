# P04 — Niri + noctalia active
# Expected: noctalia IPC dispatchers in niri binds, swaync suppressed,
# waybar-niri absent (default off; blocked by contract when shell active).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./04-niri-noctalia;
  hm = H.getHm config;
  niriBinds = hm.programs.niri.settings.binds;
  launcherSpawn = niriBinds."Mod+Shift+A".action.spawn;
  lockSpawn = niriBinds."Mod+Delete".action.spawn;
in
nix-tests.runTests {
  "P04: niri + noctalia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed — coexists with noctalia (binds dispatch to noctalia IPC)" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync suppressed — noctalia active on niri" =
      helpers.isFalse hm.services.swaync.enable;
    "Mod+Shift+A spawns noctalia launcher IPC" =
      helpers.isTrue (builtins.any (elem: lib.hasInfix "noctalia-shell ipc call launcher toggle" elem) launcherSpawn);
    "Mod+Delete spawns noctalia lock IPC" =
      helpers.isTrue (builtins.any (elem: lib.hasInfix "noctalia-shell ipc call lockScreen lock" elem) lockSpawn);
  };
}
