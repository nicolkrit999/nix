let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    (src + "/templates/tests/nixos/test-airplane/shared/nixos-extra-x86_64")
    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/services/airplane.nix")
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
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [ (src + "/templates/tests/nixos/test-airplane/shared/host-airplane.nix") ] ++ nixosPaths;
    exclude = [ ];
  }).airplane-host;

  twin = mods: (host.extendModules { modules = mods; }).config;
  force = lib.mkOverride 10;
  variants = {
    nm-off = host.config;
    nm-on = twin [{ networking.networkmanager.enable = force true; }];
    nm-on-disabled = twin [{ networking.networkmanager.enable = force true; myconfig.services.airplane.enable = force false; }];
    nm-off-forced = twin [{ myconfig.services.airplane.enable = force true; }];
    nm-on-forced = twin [{ networking.networkmanager.enable = force true; myconfig.services.airplane.enable = force true; }];
  };

  hmOf = c: c.home-manager.users.krit;
  pkgOf = c: lib.findFirst (p: (p.name or "") == "airplane") null (hmOf c).home.packages;
  aliasesOf = c: lib.filterAttrs (n: _: lib.hasPrefix "airplane" n) (hmOf c).home.shellAliases;
  failing = c: lib.filter (a: !a.assertion && lib.hasInfix "myconfig.services.airplane" a.message) c.assertions;
  expectedAliases = { airplane-on = "airplane full"; airplane-off = "airplane off"; };

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  show = builtins.toJSON;

  scriptSrc = builtins.readFile (src + "/modules/nixos/services/airplane/airplane.sh");
  pkgText = c: (pkgOf c).text or "";
  strictHeader = t: lib.all (o: lib.hasInfix "set -o ${o}" t) [ "errexit" "nounset" "pipefail" ];
  pathLine = t: lib.concatStringsSep "\n" (lib.filter (lib.hasPrefix "export PATH=") (lib.splitString "\n" t));
  pathHas = t: names: lib.filter (n: !(lib.hasInfix "-${n}-" (pathLine t))) names;
  usedBins = [ "nmcli" "rfkill" "notify-send" "logger" "pkill" ];

  present = c: chk (pkgOf c != null && aliasesOf c == expectedAliases) "package ${show (pkgOf c != null)}, aliases ${show (aliasesOf c)}";
  absent = c: chk (pkgOf c == null && aliasesOf c == { }) "package ${show (pkgOf c != null)}, aliases ${show (aliasesOf c)}";
  onNm = variants.nm-on;
in
{
  results = {
    "option defaults to NetworkManager: off without it" =
      chk (!variants.nm-off.myconfig.services.airplane.enable) "enable ${show variants.nm-off.myconfig.services.airplane.enable} without NetworkManager";
    "option defaults to NetworkManager: on with it" =
      chk onNm.myconfig.services.airplane.enable "enable ${show onNm.myconfig.services.airplane.enable} with NetworkManager";
    "NetworkManager on: airplane package and the airplane-on / airplane-off aliases installed" = present onNm;
    "NetworkManager off: no package, no aliases" = absent variants.nm-off;
    "explicitly disabled with NetworkManager on: no package, no aliases" = absent variants.nm-on-disabled;
    "aliases map to full and off" = chk (aliasesOf onNm == expectedAliases) "aliases ${show (aliasesOf onNm)}";
    "forced on without NetworkManager: assertion fires" =
      chk (lib.length (failing variants.nm-off-forced) == 1) "failing assertions ${show (map (a: a.message) (failing variants.nm-off-forced))}";
    "forced on with NetworkManager: no airplane assertion fails" =
      chk (failing variants.nm-on-forced == [ ]) "failing ${show (map (a: a.message) (failing variants.nm-on-forced))}";
    "default NetworkManager host: no airplane assertion fails" = chk (failing onNm == [ ]) "failing ${show (map (a: a.message) (failing onNm))}";
    "package text is the strict-mode header + airplane.sh" =
      chk (strictHeader (pkgText onNm) && lib.hasInfix scriptSrc (pkgText onNm)) "header ${show (strictHeader (pkgText onNm))}, script embedded ${show (lib.hasInfix scriptSrc (pkgText onNm))}";
    "runtime inputs put nmcli, rfkill/logger, notify-send, pkill on the script PATH (no reliance on the user PATH)" =
      let missing = pathHas (pkgText onNm) [ "networkmanager" "util-linux" "libnotify" "procps" ]; in chk (missing == [ ]) "missing from export PATH: ${show missing}";
    "services.airplane.package (waybar clicks) is the installed airplane" =
      chk (pkgOf onNm != null && onNm.myconfig.services.airplane.package.outPath == (pkgOf onNm).outPath) "option ${onNm.myconfig.services.airplane.package.name}";
    "script still calls every binary the runtime inputs are there for (no stale runtimeInputs)" =
      let called = lib.filter (b: lib.hasInfix "${b} " scriptSrc) usedBins; in chk (called == usedBins) "script no longer calls ${show (lib.subtractLists called usedBins)}, runtimeInputs may be stale";
  };

  control = {
    "present detector rejects the NetworkManager-off host" = chk (present variants.nm-off != "ok") "present passed without airplane";
    "absent detector rejects the NetworkManager-on host" = chk (absent onNm != "ok") "absent passed with airplane";
    "failing-assertion filter bites on a broken assertion" =
      chk (failing { assertions = [{ assertion = false; message = "myconfig.services.airplane x"; } { assertion = false; message = "other"; } { assertion = true; message = "myconfig.services.airplane y"; }]; } != [ ]) "filter missed";
    "strict-mode detector rejects a bare script" = chk (!strictHeader "#!/bin/bash\necho hi\n") "accepted a script without set -o";
    "PATH check rejects a PATH without libnotify" = chk (pathHas "export PATH=\"/nix/store/a-networkmanager-1/bin:/nix/store/b-util-linux-2/bin:$PATH\"" [ "networkmanager" "libnotify" ] == [ "libnotify" ]) "path check accepted a missing runtime input";
    "NetworkManager twin really flips the option" = chk (onNm.networking.networkmanager.enable && !variants.nm-off.networking.networkmanager.enable) "twin did not change networkmanager.enable";
  };
}
