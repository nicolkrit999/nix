# C01 — Two shells (caelestia + noctalia) both active on Hyprland
# Expected: cross-shell assertion in noctalia-main.nix fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-two-shells-on-hyprland;
in
nix-tests.runTests {
  "C01: two shells active on hyprland must assert" = helpers: {
    "cross-shell assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "Both caelestia and noctalia are active on Hyprland" config);
  };
}
