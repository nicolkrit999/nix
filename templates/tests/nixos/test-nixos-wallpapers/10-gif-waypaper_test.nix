{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  gifHash = "1v3h995fifxcdvrizr5n99h0bmja7khzi89bh33d869psrjc4ssp";
  config = H.getConfig ./10-gif-waypaper H.nixosExtraX86;
in
nix-tests.runTests {
  "W10: gifURL set + waypaper enabled → waypaper wins over gif branch" = helpers: {
    "hyprland exec contains waypaper --restore (waypaper branch beats gif branch)" =
      helpers.isTrue (H.hyprExecHas "waypaper --restore" config);
    "hyprland exec does NOT contain awww-daemon (waypaper wins)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain gif sha fragment (waypaper wins)" =
      helpers.isFalse (H.hyprExecHas gifHash config);
    "mango exec contains waypaper --restore (waypaper branch beats gif branch)" =
      helpers.isTrue (H.mangoExecHas "waypaper --restore" config);
    "mango exec does NOT contain awww-daemon (waypaper wins)" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn contains waypaper --restore (waypaper branch beats gif branch)" =
      helpers.isTrue (H.niriSpawnHas "waypaper --restore" config);
    "niri spawn does NOT contain awww-daemon (waypaper wins)" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "waypaper IS in home packages" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
  };
}
