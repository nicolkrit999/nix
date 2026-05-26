# C04 — waybar-niri enabled while noctalia is active on Niri
# Expected: waybar-niri assertion fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./04-waybar-niri-with-noctalia;
in
nix-tests.runTests {
  "C04: waybar-niri + active noctalia must assert" = helpers: {
    "waybar-niri conflict assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "waybar-niri is enabled together with an active noctalia shell on Niri" config);
  };
}
