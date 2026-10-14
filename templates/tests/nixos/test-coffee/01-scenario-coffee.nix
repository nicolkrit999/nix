let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    (src + "/templates/tests/nixos/test-coffee/shared/nixos-extra-x86_64")
    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/power/coffee.nix")
    (src + "/modules/nixos/specializations/guest.nix")
    (src + "/modules/nixos/specializations/secure-travel.nix")
  ];

  host = (denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inputs = flake.inputs;
      moduleSystem = "nixos";
    };
    paths = [ (src + "/templates/tests/nixos/test-coffee/shared/host-coffee.nix") ] ++ nixosPaths;
    exclude = [ ];
  }).coffee-host;

  twin = mods: (host.extendModules { modules = mods; }).config;
  force = lib.mkOverride 10;
  wmOnly = wm: twin [{
    myconfig.programs = { hyprland.enable = force false; niri.enable = force false; mango.enable = force false; } // { ${wm}.enable = force true; };
  }];
  inSpec = sp: m: { specialisation.${sp}.configuration = m; };
  leak = sp: twin [ (inSpec sp { myconfig.programs.mango.enable = force true; }) ];
  leakCoffee = sp: twin [ (inSpec sp { myconfig.programs.mango.enable = force true; myconfig.services.coffee.enable = force true; }) ];

  main = host.config;
  variants = {
    hyprland = main;
    niri = wmOnly "niri";
    mango = wmOnly "mango";
    no-wm = twin [{ myconfig.programs.hyprland.enable = force false; }];
    coffee-disabled = twin [{ myconfig.services.coffee.enable = false; }];
  };
  spec = c: sp: c.specialisation.${sp}.configuration;

  names = [ "coffee-on" "coffee-off" "coffee-status" ];
  keys = { SuspendKeyIgnoreInhibited = "yes"; HibernateKeyIgnoreInhibited = "yes"; };
  hmOf = c: c.home-manager.users.krit;
  coffeePkgs = c: lib.filter (p: lib.elem (p.name or "") names) (hmOf c).home.packages;
  coffeeNames = c: map (p: p.name) (coffeePkgs c);
  login = c: c.services.logind.settings.Login or { };
  coffeeKeys = c: builtins.intersectAttrs keys (login c);

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  show = builtins.toJSON;

  present = c: chk (coffeeNames c == names && coffeeKeys c == keys) "packages ${show (coffeeNames c)}, logind keys ${show (coffeeKeys c)}";
  absent = c: chk (coffeeNames c == [ ] && coffeeKeys c == { }) "packages ${show (coffeeNames c)}, logind keys ${show (coffeeKeys c)}";

  added = on: off: lib.subtractLists off on;
  sysUnits = c: lib.attrNames c.systemd.services;
  userUnits = c: lib.attrNames (hmOf c).systemd.user.services;
  off = variants.coffee-disabled;

  pkgText = n: (lib.findFirst (p: p.name == n) null (coffeePkgs main)).text or "";
  libSrc = builtins.readFile (src + "/modules/nixos/services/power/coffee/coffee-lib.sh");
  bodySrc = n: builtins.readFile (src + "/modules/nixos/services/power/coffee/${n}.sh");
  strictHeader = t: lib.all (o: lib.hasInfix "set -o ${o}" t) [ "errexit" "nounset" "pipefail" ];

  hypridleSet = c: (hmOf c).services.hypridle;
  hypridleConf = c: (hmOf c).xdg.configFile."hypr/hypridle.conf".text or "";
  ignoresInhibit = general: conf: (general.ignore_systemd_inhibit or false) == true || builtins.match ".*ignore_systemd_inhibit *= *(true|1|yes|on).*" conf != null;
in
{
  results = {
    "option services.coffee.enable defaults to true" =
      chk (host.options.myconfig.services.coffee.enable.default == true && main.myconfig.services.coffee.enable) "default ${show host.options.myconfig.services.coffee.enable.default}, host value ${show main.myconfig.services.coffee.enable}";

    "hyprland only: coffee-on/off/status installed, Suspend/HibernateKeyIgnoreInhibited = yes" = present variants.hyprland;
    "niri only: coffee-on/off/status installed, Suspend/HibernateKeyIgnoreInhibited = yes" = present variants.niri;
    "mango only: coffee-on/off/status installed, Suspend/HibernateKeyIgnoreInhibited = yes" = present variants.mango;
    "no WM: no coffee scripts, no logind key settings" = absent variants.no-wm;
    "coffee disabled (WM on): no coffee scripts, no logind key settings" = absent variants.coffee-disabled;

    "guest: no coffee scripts, no logind key settings" = absent (spec main "guest");
    "secure-travel: no coffee scripts, no logind key settings" = absent (spec main "secure-travel");
    "guest with a WM leaked back in: coffee still absent" = absent (spec (leak "guest") "guest");
    "secure-travel with a WM leaked back in: coffee still absent" = absent (spec (leak "secure-travel") "secure-travel");
    "control: guest with a leaked WM and coffee re-enabled has coffee" = present (spec (leakCoffee "guest") "guest");
    "control: secure-travel with a leaked WM and coffee re-enabled has coffee" = present (spec (leakCoffee "secure-travel") "secure-travel");

    "coffee declares no system unit (inhibitor is transient)" =
      let a = added (sysUnits main) (sysUnits off); in chk (a == [ ]) "coffee adds system units ${show a}";
    "coffee declares no user unit (no lid watcher, inhibitor is transient)" =
      let a = added (userUnits main) (userUnits off); in chk (a == [ ]) "coffee adds user units ${show a}";
    "coffee changes logind only by the two *KeyIgnoreInhibited keys" =
      chk (main.services.logind.settings == lib.recursiveUpdate off.services.logind.settings { Login = keys; })
        "logind settings differ beyond the two keys: ${show (lib.attrNames (login main))} vs ${show (lib.attrNames (login off))}";

    "each package text is the strict-mode header + coffee-lib.sh + its own script" =
      let bad = lib.filter (n: !(strictHeader (pkgText n) && lib.hasInfix (libSrc + bodySrc n) (pkgText n))) names;
      in chk (bad == [ ]) "mismatched package text: ${show bad}";

    "hypridle is enabled with a generated config (subject of the next check)" =
      chk ((hypridleSet main).enable && lib.hasInfix "lock_cmd" (hypridleConf main)) "hypridle enable ${show (hypridleSet main).enable}, conf length ${toString (lib.stringLength (hypridleConf main))}";
    "hypridle does not set ignore_systemd_inhibit (it must honour coffee's idle lock)" =
      chk (!ignoresInhibit ((hypridleSet main).settings.general or { }) (hypridleConf main)) "hypridle ignores systemd inhibitors";
  };

  control = {
    "unit diff detects an added unit" = chk (added [ "a" "coffee-lid" ] [ "a" ] == [ "coffee-lid" ] && added [ "a" ] [ "a" ] == [ ]) "diff helper broken";
    "ignore_systemd_inhibit detector bites (settings)" = chk (ignoresInhibit { ignore_systemd_inhibit = true; } "") "missed settings";
    "ignore_systemd_inhibit detector bites (config text)" = chk (ignoresInhibit { } "general {\n  ignore_systemd_inhibit = true\n}") "missed text";
    "ignore_systemd_inhibit detector accepts false" = chk (!ignoresInhibit { ignore_systemd_inhibit = false; } "ignore_systemd_inhibit = false") "flagged false";
    "absent detector rejects installed coffee" = chk (absent variants.hyprland != "ok") "absent passed on a host with coffee";
    "present detector rejects missing coffee" = chk (present variants.no-wm != "ok") "present passed on a host without coffee";
    "strict-mode detector rejects a bare script" = chk (!strictHeader "#!/bin/bash\necho hi\n") "accepted a script without set -o";
  };
}
