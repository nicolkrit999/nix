{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./09-named-monitor H.nixosExtraX86;
in
nix-tests.runTests {
  "W09: named monitor generates -o flag in awww commands" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains -o DP-1 for named monitor" =
      helpers.isTrue (H.hyprExecHas "-o DP-1" config);
    "hyprland exec contains awww img" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec contains -o DP-1 for named monitor" =
      helpers.isTrue (H.mangoExecHas "-o DP-1" config);
    "mango exec contains awww img" =
      helpers.isTrue (H.mangoExecHas "awww img" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn contains -o DP-1 for named monitor" =
      helpers.isTrue (H.niriSpawnHas "-o DP-1" config);
    "niri spawn contains awww img" =
      helpers.isTrue (H.niriSpawnHas "awww img" config);
    "niri spawn does NOT contain waypaper --restore" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
  };
}
