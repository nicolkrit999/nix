# C03 — waybar-hyprland enabled while noctalia is active on Hyprland
# Expected: waybar-hyprland assertion fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./03-waybar-hyprland-with-noctalia;
in
nix-tests.runTests {
  "C03: waybar-hyprland + active noctalia must assert" = helpers: {
    "waybar-hyprland conflict assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "waybar-hyprland is enabled together with an active shell" config);
  };
}
