# W09 - declared-only: a still image on the named monitor DP-1, no "*" entry.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./09-named-monitor H.nixosExtraX86;
in
nix-tests.runTests {
  "W09: named monitor generates a DP-1=image: spec, no fallback" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "DP-1=image:" "DP-1=image:")
      (E.noSpec "wildcard fallback entry" "*=")
      (E.noSpec "video entry" "=video:")
      E.noDirectAwww
    ];
}
