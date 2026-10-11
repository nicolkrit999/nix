{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  scen = d: let c = H.getConfig d; in { inherit c; hm = H.getHm c; once = c.myconfig.programs.hyprland.execOnce; };
  none = scen ./04-hyprland-no-shell;
  dorm = scen ./05-dormant-both-hyprland;
  has = needle: xs: builtins.any (x: lib.hasInfix needle x) xs;
  pkgNames = hm: map (p: p.name or (p.pname or "")) hm.home.packages;
  swaync = s: s.hm.systemd.user.services.swaync.Unit.PartOf;
  consumers = s: helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass s.c);
    "swayosd-server present" = helpers.isTrue (s.hm.systemd.user.services ? "swayosd-server");
    "swaync enabled" = helpers.isTrue s.hm.services.swaync.enable;
    "swaync PartOf is exactly hyprland-session.target" = helpers.isTrue (swaync s == [ "hyprland-session.target" ]);
    "execOnce has no start-noctalia" = helpers.isFalse (has "start-noctalia" s.once);
    "execOnce has no caelestiaqs" = helpers.isFalse (has "caelestiaqs" s.once);
    "start-noctalia not in home.packages" = helpers.isFalse (builtins.elem "start-noctalia" (pkgNames s.hm));
    "caelestiaqs not in home.packages" = helpers.isFalse (builtins.elem "caelestiaqs" (pkgNames s.hm));
  };
in
nix-tests.runTests {
  "C05: hyprland, no shell" = consumers none;
  "C06: hyprland, both shells dormant (enable=false, enableOnHyprland=true)" = consumers dorm;
}
