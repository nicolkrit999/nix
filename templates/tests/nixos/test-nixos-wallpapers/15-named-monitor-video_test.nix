# W15 - declared-only video: DP-1=video: spec, no "*" entry, no awww-daemon.
# Mirror of W09 for the video path.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./15-named-monitor-video H.nixosExtraX86;
in
nix-tests.runTests {
  "W15: named monitor generates a DP-1=video: spec, no fallback" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.noDaemon
      (E.spec "DP-1=video:" "DP-1=video:")
      (E.noSpec "wildcard fallback entry" "*=")
      (E.noSpec "image entry" "=image:")
      E.noDirectMpv
    ];
}
