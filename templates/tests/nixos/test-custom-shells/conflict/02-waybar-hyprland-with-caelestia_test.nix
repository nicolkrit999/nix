# C02 — waybar-hyprland enabled while caelestia is active on Hyprland
# Expected: waybar-hyprland assertion fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./02-waybar-hyprland-with-caelestia;
in
nix-tests.runTests {
  "C02: waybar-hyprland + active caelestia must assert" = helpers: {
    "waybar-hyprland conflict assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "waybar-hyprland is enabled together with an active shell" config);
  };
}
