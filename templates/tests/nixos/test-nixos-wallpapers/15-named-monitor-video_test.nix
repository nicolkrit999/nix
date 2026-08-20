# W15 - named monitor generates the explicit -o flag in mpvpaper commands
# too (not just awww). Mirror of W09 but for the video/mpvpaper dispatch path.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./15-named-monitor-video H.nixosExtraX86;
in
nix-tests.runTests {
  "W15: named monitor generates -o DP-1 in mpvpaper commands" = helpers: {
    "hyprland exec contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" DP-1 for named monitor" =
      helpers.isTrue (H.hyprExecHas "mpvpaper -f -o \\\"loop mute=yes panscan=1.0\\\" DP-1" config);
    "hyprland exec does NOT contain mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL" =
      helpers.isFalse (H.hyprExecHas "mpvpaper -f -o \\\"loop mute=yes panscan=1.0\\\" ALL" config);
    "hyprland exec does NOT contain awww img" =
      helpers.isFalse (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" DP-1 for named monitor" =
      helpers.isTrue (H.mangoExecHas "mpvpaper -f -o \"loop mute=yes panscan=1.0\" DP-1" config);
    "mango exec does NOT contain awww img" =
      helpers.isFalse (H.mangoExecHas "awww img" config);
    "niri spawn contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" DP-1 for named monitor" =
      helpers.isTrue (H.niriSpawnHas "mpvpaper -f -o \"loop mute=yes panscan=1.0\" DP-1" config);
    "niri spawn does NOT contain awww img" =
      helpers.isFalse (H.niriSpawnHas "awww img" config);
  };
}
