# P05 — Niri, no shell
# Expected: swaync present, Mod+Shift+A no-op, Mod+Delete loginctl.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./05-niri-no-shell;
  hm = H.getHm config;
  niriBinds = hm.programs.niri.settings.binds;
in
nix-tests.runTests {
  "P05: niri, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "Mod+Shift+A is a no-op (spawn true)" =
      helpers.isEq niriBinds."Mod+Shift+A".action.spawn [ "true" ];
    "Mod+Delete dispatches to loginctl lock-session" =
      helpers.isEq niriBinds."Mod+Delete".action.spawn [ "loginctl" "lock-session" ];
  };
}
