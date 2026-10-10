# W18 - declared-only with two outputs: DP-1 (still) + HDMI-A-1 (video), no "*".
# Both specs reach every supervisor, no fallback entry exists, and awww-daemon
# starts because DP-1 is a still image.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./18-two-declared-no-fallback H.nixosExtraX86;
in
nix-tests.runTests {
  "W18: two declared outputs, no fallback" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "DP-1=image:" "DP-1=image:")
      (E.spec "HDMI-A-1=video:" "HDMI-A-1=video:")
      (E.noSpec "wildcard fallback entry" "*=")
      E.noDirectAwww
      E.noDirectMpv
    ];
}
