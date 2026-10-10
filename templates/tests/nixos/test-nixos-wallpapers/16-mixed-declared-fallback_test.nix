# W16 - declared DP-1 (still image) + "*" fallback (video), skwdWall disabled.
# Each WM passes two separate specs to its supervisor ("*" is a fallback
# resolved at runtime, never an ALL wallpaper stacked under DP-1), exactly one
# "*=" entry exists, and awww-daemon starts because DP-1 is a still image.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./16-mixed-declared-fallback H.nixosExtraX86;
in
nix-tests.runTests {
  "W16: declared still + video fallback" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "DP-1=image:" "DP-1=image:")
      (E.spec "*=video: (fallback entry)" "*=video:")
      (E.noSpec "DP-1=video: (declared output keeps its still)" "DP-1=video:")
      (E.noSpec "*=image: (fallback is the video)" "*=image:")
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "hyprland has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "hyprland" "*=" config == 1);
      "mango has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "mango" "*=" config == 1);
      "niri has exactly one *= fallback entry" = helpers.isTrue (H.wmCount "niri" "*=" config == 1);
    };
}
