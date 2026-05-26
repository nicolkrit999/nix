# C05 — waybar-mango enabled while noctalia is active on Mango
# Expected: waybar-mango assertion fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./05-waybar-mango-with-noctalia;
in
nix-tests.runTests {
  "C05: waybar-mango + active noctalia must assert" = helpers: {
    "waybar-mango conflict assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "waybar-mango is enabled together with an active noctalia shell on Mango" config);
  };
}
