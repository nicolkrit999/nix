let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  fx = import ../../lib/fixture-host.nix flake;
  inherit (flake.inputs.nixpkgs) lib;

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  secret = "org.freedesktop.impl.portal.Secret";
  desktops = [ "hyprland" "niri" "mango" ];

  host = fx.mkNixos [{ myconfig.specializations.ryoku.enable = true; }];
  specOf = h: h.config.specialisation.ryoku.configuration;
  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
  ryokuUser = (specOf host).myconfig.constants.user;

  table = (specOf host).xdg.portal.config;
  dupRoute = host.extendModules {
    modules = [{ specialisation.ryoku.configuration.xdg.portal.config = lib.mkOverride 40 (lib.recursiveUpdate table { hyprland.${secret} = "gnome-keyring;gnome-keyring"; }); }];
  };
  divergent = host.extendModules {
    modules = [{ specialisation.ryoku.configuration.home-manager.users.${ryokuUser}.xdg.portal.config = lib.mkOverride 40 (lib.recursiveUpdate table { hyprland.default = "gtk"; }); }];
  };

  routeOnce = cfg: lib.all (d: lib.toList (cfg.xdg.portal.config.${d}.${secret} or [ ]) == [ "gnome-keyring" ]) desktops;
  noDuplicates = cfg: lib.all (iface: lib.all (v: let l = lib.splitString ";" v; in lib.unique l == l) (lib.attrValues iface)) (lib.attrValues cfg.xdg.portal.config);
  equalPortal = c: (hmOf c).xdg.portal.config == c.xdg.portal.config;
  secretOk = c: routeOnce c && routeOnce (hmOf c);
in
{
  report = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (k: v: "${k}\t${v}") {
      "fixture ryoku: the spec exists and enables programs.ryoku (the base does not)" =
        chk ((specOf host).programs.ryoku.enable && !host.config.programs.ryoku.enable) "ryoku spec missing, programs.ryoku off in it, or on in the base";
      "fixture ryoku: Secret routes to gnome-keyring exactly once in hyprland, niri and mango (system and HM)" =
        chk (secretOk (specOf host)) "Secret route is not a single gnome-keyring: ${builtins.toJSON (map (d: (specOf host).xdg.portal.config.${d}.${secret} or null) desktops)}";
      "fixture ryoku: HM portal config equals the system portal config" =
        chk (equalPortal (specOf host)) "HM and system xdg.portal.config differ in the ryoku spec";
      "fixture ryoku: no portal route lists a backend twice (Ryoku's own fragments are not appended)" =
        chk (noDuplicates (specOf host)) "a route lists a backend twice: ${builtins.toJSON (specOf host).xdg.portal.config}";
      "control: a Secret route listing gnome-keyring twice is flagged" =
        chk (!(secretOk (specOf dupRoute)) && !(noDuplicates (specOf dupRoute))) "the probes accept a duplicated Secret route";
      "control: a HM table that diverges from the system table is flagged" =
        chk (!(equalPortal (specOf divergent))) "the equality probe accepts a diverging HM portal config";
    }) + "\n";
}
