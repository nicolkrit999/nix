# W17 - inverse of W16: declared DP-1 (video) + "*" fallback (still image).
# Fallback must be a separate "*=image:" spec, not stacked under DP-1, and
# awww-daemon starts because the fallback is a still image.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./17-mixed-declared-video-fallback-still H.nixosExtraX86;
in
nix-tests.runTests {
  "W17: declared video + still fallback" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "DP-1=video:" "DP-1=video:")
      (E.spec "*=image: (fallback entry)" "*=image:")
      (E.noSpec "DP-1=image: (declared output keeps its video)" "DP-1=image:")
      (E.noSpec "*=video: (fallback is the still)" "*=video:")
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "hyprland has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "hyprland" "*=" config == 1);
      "mango has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "mango" "*=" config == 1);
      "niri has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "niri" "*=" config == 1);
    };
}
