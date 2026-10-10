# W11 - noctalia enable=true but all enableOnXxx=false: no WM is shell-owned,
# so every WM falls through to its own wallpaper supervisor.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./11-noctalia-dormant H.nixosExtraX86;
in
nix-tests.runTests {
  "W11: noctalia dormant on every WM -> all WMs run the wallpaper supervisor" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "*=image:" "*=image:")
    ];
}
