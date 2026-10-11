{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  multi = H.getConfig ./06-multi-wm-shell-on-niri;
  mhm = H.getHm multi;
  nowm = H.getConfig ./07-no-wm;
  nhm = H.getHm nowm;
  hyp = H.getConfig ./04-hyprland-no-shell;
  hhm = H.getHm hyp;
in
nix-tests.runTests {
  "C07: hyprland+niri+mango, noctalia only on niri" = helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass multi);
    "swayosd-server kept for the other WMs" = helpers.isTrue (mhm.systemd.user.services ? "swayosd-server");
    "swaync kept for the other WMs" = helpers.isTrue mhm.services.swaync.enable;
    "swaync PartOf excludes niri, keeps hyprland and mango" =
      helpers.isTrue (mhm.systemd.user.services.swaync.Unit.PartOf == [ "hyprland-session.target" "mango-session.target" ]);
    "hypridle enabled" = helpers.isTrue mhm.services.hypridle.enable;
  };
  "C08: no WM enabled" = helpers: {
    "swayosd-server absent" = helpers.isFalse (nhm.systemd.user.services ? "swayosd-server");
    "swaync disabled" = helpers.isFalse nhm.services.swaync.enable;
    "hypridle disabled" = helpers.isFalse nhm.services.hypridle.enable;
    "hyprlock disabled" = helpers.isFalse nhm.programs.hyprlock.enable;
  };
  "C09: control, hyprland enabled" = helpers: {
    "hypridle enabled" = helpers.isTrue hhm.services.hypridle.enable;
    "hyprlock enabled" = helpers.isTrue hhm.programs.hyprlock.enable;
  };
}
