{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  scen = d: let c = H.getConfig d; in { inherit c; hm = H.getHm c; once = c.myconfig.programs.hyprland.execOnce; };
  cae = scen ./01-caelestia-hyprland;
  nocH = scen ./08-noctalia-hyprland;
  nocN = scen ./02-noctalia-niri;
  nocM = scen ./03-noctalia-mango;
  has = needle: xs: builtins.any (x: lib.hasInfix needle x) xs;
  pkgNames = hm: map (p: p.name or (p.pname or "")) hm.home.packages;
in
nix-tests.runTests {
  "C01: caelestia active on hyprland" = helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass cae.c);
    "swayosd-server absent" = helpers.isFalse (cae.hm.systemd.user.services ? "swayosd-server");
    "swaync disabled" = helpers.isFalse cae.hm.services.swaync.enable;
    "execOnce launches caelestiaqs" = helpers.isTrue (has "caelestiaqs" cae.once);
    "execOnce does not launch start-noctalia" = helpers.isFalse (has "start-noctalia" cae.once);
    "caelestiaqs in home.packages" = helpers.isTrue (builtins.elem "caelestiaqs" (pkgNames cae.hm));
    "start-noctalia not in home.packages" = helpers.isFalse (builtins.elem "start-noctalia" (pkgNames cae.hm));
  };
  "C02: noctalia active on hyprland" = helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass nocH.c);
    "swayosd-server absent" = helpers.isFalse (nocH.hm.systemd.user.services ? "swayosd-server");
    "swaync disabled" = helpers.isFalse nocH.hm.services.swaync.enable;
    "execOnce launches start-noctalia" = helpers.isTrue (has "start-noctalia" nocH.once);
    "execOnce does not launch caelestiaqs" = helpers.isFalse (has "caelestiaqs" nocH.once);
    "start-noctalia in home.packages" = helpers.isTrue (builtins.elem "start-noctalia" (pkgNames nocH.hm));
  };
  "C03: noctalia active on niri" = helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass nocN.c);
    "swayosd-server absent" = helpers.isFalse (nocN.hm.systemd.user.services ? "swayosd-server");
    "swaync disabled" = helpers.isFalse nocN.hm.services.swaync.enable;
    "start-noctalia in home.packages" = helpers.isTrue (builtins.elem "start-noctalia" (pkgNames nocN.hm));
  };
  "C04: noctalia active on mango" = helpers: {
    "no failing assertions" = helpers.isTrue (H.allAssertionsPass nocM.c);
    "swayosd-server absent" = helpers.isFalse (nocM.hm.systemd.user.services ? "swayosd-server");
    "swaync disabled" = helpers.isFalse nocM.hm.services.swaync.enable;
    "start-noctalia in home.packages" = helpers.isTrue (builtins.elem "start-noctalia" (pkgNames nocM.hm));
  };
}
