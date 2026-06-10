{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./11-noctalia-dormant H.nixosExtraX86;
in
nix-tests.runTests {
  "W11: noctalia enable=true but all enableOnXxx=false → all WMs fall through to awww" = helpers: {
    "hyprland exec contains awww-daemon (noctalia dormant, not shell-owned)" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon (noctalia dormant, not shell-owned)" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec contains awww img" =
      helpers.isTrue (H.mangoExecHas "awww img" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon (noctalia dormant, not shell-owned)" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn contains awww img" =
      helpers.isTrue (H.niriSpawnHas "awww img" config);
    "niri spawn does NOT contain waypaper --restore" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
  };
}
