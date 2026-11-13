let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;
  shared = src + "/templates/tests/nixos/test-lanzaboote/shared";

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
    paths = [
      (shared + "/host-lanzaboote.nix")
      (shared + "/impermanence-stub.nix")
      (shared + "/nixos-extra-x86_64")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/services/lanzaboote.nix")
    ];
    exclude = [ ];
  }).lanzaboote-host;

  force = lib.mkOverride 10;
  twin = mods: host.extendModules { modules = lib.toList mods; };
  sb = o: { myconfig.services.lanzaboote = o; };
  on = sb { enable = true; };
  emergency = { boot.initrd.systemd.emergencyAccess = true; };
  imperm = { myconfig.services.impermanence.enable = true; };

  defaultBundle = "/persist/var/lib/sbctl";
  customBundle = "/persist/custom/sbctl-fixture";
  outsideBundle = "/var/lib/sbctl-fixture";
  prefixTrapBundle = "/persistent/sbctl-fixture";

  off = host;
  enabled = twin on;
  custom = twin (sb { enable = true; pkiBundle = customBundle; configurationLimit = 3; });
  grubForced = twin [ on { boot.loader.grub.enable = force true; } ];
  outsideImperm = twin [ (sb { enable = true; pkiBundle = outsideBundle; }) imperm ];
  outsidePlain = twin (sb { enable = true; pkiBundle = outsideBundle; });
  prefixTrap = twin [ (sb { enable = true; pkiBundle = prefixTrapBundle; }) imperm ];
  insideImperm = twin [ on imperm ];
  sdbOn = { boot.loader.systemd-boot.enable = true; };
  sdbEnabledMod = twin [ on sdbOn ];
  sdbDisabledMod = twin sdbOn;
  withMode = v: twin (sb { enable = true; consoleMode = v; });
  validModes = [ "keep" "auto" "max" "5" "0" "12" ];
  invalidModes = [ "abc" "-1" "" "5x" "keepx" " 5" ];
  modeOff = twin (sb { consoleMode = "abc"; });
  plainSecure = twin (sb { enable = true; secureBoot = true; });
  secureNoEnable = twin (sb { secureBoot = true; });
  secureEmergency = twin [ (sb { enable = true; secureBoot = true; }) emergency ];
  secureEmergencyNoEnable = twin [ (sb { secureBoot = true; }) emergency ];
  emergencyOnly = twin [ on emergency ];
  limitFive = twin (sb { enable = true; configurationLimit = 5; });
  keysOn = twin [ on { boot.lanzaboote = { autoGenerateKeys.enable = true; autoEnrollKeys.enable = true; measuredBoot.enable = true; }; } ];

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  has = x: xs: builtins.elem x xs;
  failed = t: lib.filter (a: !a.assertion) t.config.assertions;
  mine = t: lib.filter (a: lib.hasInfix "services.lanzaboote" a.message) (failed t);
  firing = n: t: lib.filter (a: lib.hasInfix n a.message) (mine t);
  failingCount = t: lib.length (mine t);
  grubMsg = "boot.loader.grub.enable must be false";
  persistMsg = "must live under /persist/";
  tmpfilesOf = t: t.config.systemd.tmpfiles.rules;
  rule = bundle: "d ${bundle} 0700 root root -";
  sbctlRules = t: lib.filter (r: lib.hasInfix "sbctl" r) (tmpfilesOf t);
  etc = t: t.config.environment.etc;
  confValue = t: (etc t)."sbctl/sbctl.conf".source.value or null;
  confFor = bundle: { keydir = "${bundle}/keys"; guid = "${bundle}/GUID"; };
  sbctlIn = t: has host.pkgs.sbctl.outPath (map (p: p.outPath or "") t.config.environment.systemPackages);
  lz = t: t.config.boot.lanzaboote;
  cmode = t: (lz t).settings."console-mode" or null;
  restOf = t: removeAttrs (lz t).settings [ "console-mode" ];
  modeOpt = t: t.config.myconfig.services.lanzaboote.consoleMode;
  modeMsg = "services.lanzaboote.consoleMode";
  enableMsg = "services.lanzaboote.secureBoot declares";
  emergencyMsg = "emergencyAccess is enabled";
  msgs = t: map (a: a.message) (mine t);
  modeCase = v: { inherit v; t = withMode v; };
  validCases = map modeCase validModes;
  invalidCases = map modeCase invalidModes;
  keyOpts = t: [ (lz t).autoGenerateKeys.enable (lz t).autoEnrollKeys.enable (lz t).measuredBoot.enable ];

  checks = {
    "defaults: module off, lanzaboote off" =
      chk (!(lz off).enable) "boot.lanzaboote.enable=${lib.boolToString (lz off).enable}";
    "defaults: module off writes no sbctl.conf, no sbctl tmpfiles rule, no sbctl package" =
      chk (!(etc off ? "sbctl/sbctl.conf") && sbctlRules off == [ ] && !sbctlIn off)
        "etc=${lib.boolToString (etc off ? "sbctl/sbctl.conf")} rules=${builtins.toJSON (sbctlRules off)} pkg=${lib.boolToString (sbctlIn off)}";
    "defaults: pkiBundle is /persist/var/lib/sbctl" =
      chk (off.config.myconfig.services.lanzaboote.pkiBundle == defaultBundle) off.config.myconfig.services.lanzaboote.pkiBundle;
    "defaults: configurationLimit is 10" =
      chk (off.config.myconfig.services.lanzaboote.configurationLimit == 10) (toString off.config.myconfig.services.lanzaboote.configurationLimit);
    "defaults: secureBoot is false" =
      chk (!off.config.myconfig.services.lanzaboote.secureBoot && !enabled.config.myconfig.services.lanzaboote.secureBoot) "secureBoot defaults to true";
    "defaults: consoleMode is keep, in the option and in settings console-mode when enabled" =
      chk (modeOpt off == "keep" && modeOpt enabled == "keep" && cmode enabled == "keep")
        "off=${modeOpt off} enabled=${modeOpt enabled} settings=${toString (cmode enabled)}";
    "defaults: the other loader.conf keys are exactly lanzaboote's own (default, editor, timeout), only editor differs from the module-off value" =
      chk (lib.attrNames (restOf enabled) == [ "default" "editor" "timeout" ] && removeAttrs (restOf enabled) [ "editor" ] == removeAttrs (restOf off) [ "editor" ])
        "enabled=${builtins.toJSON (restOf enabled)} off=${builtins.toJSON (restOf off)}";
    "editor: enabled writes editor = false to loader.conf (no kernel command line editing at boot)" =
      chk ((lz enabled).settings.editor == false && !enabled.config.boot.loader.systemd-boot.editor)
        "settings.editor=${builtins.toJSON (lz enabled).settings.editor}";
    "editor: every enabled twin (custom, secureBoot, limit, console mode) keeps editor = false" =
      chk (lib.all (t: (lz t).settings.editor == false) [ custom plainSecure limitFive (withMode "5") (withMode "max") ])
        "some twin has editor != false";
    "control(editor): the module-off host keeps the NixOS default editor = true, so the false value comes from the module" =
      chk ((lz off).settings.editor == true && off.config.boot.loader.systemd-boot.editor)
        "off settings.editor=${builtins.toJSON (lz off).settings.editor}";
    "editor: a host can still opt back in (plain assignment beats the module's mkDefault)" =
      chk ((lz (twin [ on { boot.loader.systemd-boot.editor = true; } ])).settings.editor == true) "override ignored";
    "control(off): the enabled twin does write all three, so the off result is not an unloaded module" =
      chk ((etc enabled ? "sbctl/sbctl.conf") && sbctlRules enabled != [ ] && sbctlIn enabled && (lz enabled).enable)
        "enabled twin lacks sbctl.conf, tmpfiles rule, package or lanzaboote";

    "enabled: boot.lanzaboote.enable is true" = chk (lz enabled).enable "boot.lanzaboote.enable=false";
    "enabled: defaults propagate (pkiBundle, configurationLimit 10)" =
      chk ((lz enabled).pkiBundle == defaultBundle && (lz enabled).configurationLimit == 10)
        "pkiBundle=${(lz enabled).pkiBundle} configurationLimit=${toString (lz enabled).configurationLimit}";
    "enabled: custom pkiBundle and configurationLimit propagate" =
      chk ((lz custom).pkiBundle == customBundle && (lz custom).configurationLimit == 3)
        "pkiBundle=${(lz custom).pkiBundle} configurationLimit=${toString (lz custom).configurationLimit}";
    "enabled: configurationLimit 5 propagates (a value other than the default and the custom twin's)" =
      chk ((lz limitFive).configurationLimit == 5 && (lz enabled).configurationLimit != 5) "configurationLimit=${toString (lz limitFive).configurationLimit}";
    "consoleMode: 5 propagates to settings console-mode and the other loader.conf keys stay unchanged" =
      chk (modeOpt (withMode "5") == "5" && cmode (withMode "5") == "5" && restOf (withMode "5") == restOf enabled && restOf enabled != { } && cmode enabled != "5")
        "option=${modeOpt (withMode "5")} settings=${toString (cmode (withMode "5"))} rest=${builtins.toJSON (restOf (withMode "5"))}";
    "consoleMode: keep, auto, max, 5, 0 and 12 are accepted, fire no assertion and propagate" =
      chk (lib.all (c: cmode c.t == c.v && failingCount c.t == 0) validCases)
        (builtins.toJSON (map (c: [ c.v (cmode c.t) (msgs c.t) ]) validCases));
    "consoleMode: abc, -1, empty, 5x, keepx and ' 5' each fire exactly the consoleMode assertion" =
      chk (lib.all (c: lib.length (firing modeMsg c.t) == 1 && failingCount c.t == 1) invalidCases)
        (builtins.toJSON (map (c: [ c.v (msgs c.t) ]) invalidCases));
    "consoleMode: the assertion message names the offending value" =
      chk (lib.all (c: lib.all (a: lib.hasInfix "\"${c.v}\"" a.message) (firing modeMsg c.t)) invalidCases) "message lacks the value";
    "control(consoleMode): a rejected value is told apart from an accepted one, and an invalid mode while the module is off fires nothing and is not written" =
      chk (failingCount (withMode "abc") != failingCount (withMode "5") && failingCount modeOff == 0 && cmode modeOff != "abc")
        "failing abc=${toString (failingCount (withMode "abc"))} five=${toString (failingCount (withMode "5"))} off=${toString (failingCount modeOff)} offSettings=${toString (cmode modeOff)}";
    "enabled: systemd-boot is forced false even against a plain definition" =
      chk (!sdbEnabledMod.config.boot.loader.systemd-boot.enable) "boot.loader.systemd-boot.enable=true";
    "control(systemd-boot): without the module the same plain definition stays true" =
      chk sdbDisabledMod.config.boot.loader.systemd-boot.enable "boot.loader.systemd-boot.enable=false without the module, so the force check cannot fail";
    "enabled: pkgs.sbctl is in systemPackages" = chk (sbctlIn enabled) "sbctl missing from environment.systemPackages";
    "enabled: tmpfiles rule is exactly `d <pkiBundle> 0700 root root -` (default and custom)" =
      chk (has (rule defaultBundle) (tmpfilesOf enabled) && has (rule customBundle) (tmpfilesOf custom))
        "default rules=${builtins.toJSON (sbctlRules enabled)} custom rules=${builtins.toJSON (sbctlRules custom)}";
    "control(tmpfiles): the custom twin does not carry the default bundle's rule" =
      chk (!has (rule defaultBundle) (tmpfilesOf custom) && !has (rule customBundle) (tmpfilesOf enabled))
        "a rule follows the wrong bundle";
    "enabled: sbctl.conf attrs are exactly keydir and guid under the SAME pkiBundle (default and custom)" =
      chk (confValue enabled == confFor defaultBundle && confValue custom == confFor customBundle)
        "default=${builtins.toJSON (confValue enabled)} custom=${builtins.toJSON (confValue custom)}";
    "control(sbctl.conf): default and custom contents differ, so a hardcoded path would fail" =
      chk (confValue enabled != confValue custom && confValue enabled != null) "sbctl.conf does not follow pkiBundle";
    "enabled: autoGenerateKeys, autoEnrollKeys and measuredBoot stay false" =
      chk (keyOpts enabled == [ false false false ]) (builtins.toJSON (keyOpts enabled));
    "control(keys): the options are readable, a twin enabling them reads true" =
      chk (keyOpts keysOn == [ true true true ]) (builtins.toJSON (keyOpts keysOn));

    "assertions: clean enabled config passes all" =
      chk (failingCount enabled == 0 && failingCount insideImperm == 0 && failingCount custom == 0 && failingCount limitFive == 0)
        (builtins.toJSON (map (a: a.message) (mine enabled ++ mine insideImperm ++ mine custom)));
    "assertions: forcing boot.loader.grub.enable fires the grub assertion exactly once" =
      chk (lib.length (firing grubMsg grubForced) == 1 && firing persistMsg grubForced == [ ])
        "grub=${toString (lib.length (firing grubMsg grubForced))} persist=${toString (lib.length (firing persistMsg grubForced))}";
    "control(grub): grub is off in the clean enabled config (lanzaboote default), so forcing it is what fires" =
      chk (!enabled.config.boot.loader.grub.enable && grubForced.config.boot.loader.grub.enable)
        "grub.enable clean=${lib.boolToString enabled.config.boot.loader.grub.enable} forced=${lib.boolToString grubForced.config.boot.loader.grub.enable}";
    "assertions: pkiBundle outside /persist/ with impermanence fires the persist assertion exactly once" =
      chk (lib.length (firing persistMsg outsideImperm) == 1 && firing grubMsg outsideImperm == [ ])
        "persist=${toString (lib.length (firing persistMsg outsideImperm))} grub=${toString (lib.length (firing grubMsg outsideImperm))}";
    "assertions: pkiBundle outside /persist/ WITHOUT impermanence passes" =
      chk (failingCount outsidePlain == 0) (builtins.toJSON (map (a: a.message) (firing "" outsidePlain)));
    "control(impermanence): the stub option really flips (same bundle passes without it, fires with it)" =
      chk (outsideImperm.config.myconfig.services.impermanence.enable && !outsidePlain.config.myconfig.services.impermanence.enable)
        "impermanence stub did not flip";
    "assertions: /persistent/... (prefix trap, no trailing slash match) fires with impermanence" =
      chk (lib.length (firing persistMsg prefixTrap) == 1) "/persistent/ passed the /persist/ prefix check";
    "assertions: the persist message names the offending path" =
      chk (lib.all (a: lib.hasInfix outsideBundle a.message) (firing persistMsg outsideImperm) && firing persistMsg outsideImperm != [ ])
        "message lacks ${outsideBundle}";
    "secureBoot: with enable and emergencyAccess off it fires nothing" =
      chk (failingCount plainSecure == 0 && plainSecure.config.myconfig.services.lanzaboote.secureBoot && !plainSecure.config.boot.initrd.systemd.emergencyAccess)
        (builtins.toJSON (msgs plainSecure));
    "secureBoot: without enable it fires exactly the enable assertion" =
      chk (lib.length (firing enableMsg secureNoEnable) == 1 && failingCount secureNoEnable == 1)
        (builtins.toJSON (msgs secureNoEnable));
    "secureBoot: with emergencyAccess on it fires exactly the emergencyAccess assertion" =
      chk (lib.length (firing emergencyMsg secureEmergency) == 1 && failingCount secureEmergency == 1 && firing enableMsg secureEmergency == [ ])
        (builtins.toJSON (msgs secureEmergency));
    "control(emergencyAccess): the option really flips, and emergencyAccess alone (secureBoot false) fires nothing" =
      chk
        (secureEmergency.config.boot.initrd.systemd.emergencyAccess && !plainSecure.config.boot.initrd.systemd.emergencyAccess
          && emergencyOnly.config.boot.initrd.systemd.emergencyAccess && failingCount emergencyOnly == 0)
        (builtins.toJSON (msgs emergencyOnly));
    "control(secureBoot): with neither enable nor secureBoot and emergencyAccess on nothing fires, and with secureBoot but no enable only the enable assertion fires" =
      chk (failingCount (twin emergency) == 0 && failingCount secureEmergencyNoEnable == 1 && firing emergencyMsg secureEmergencyNoEnable == [ ])
        (builtins.toJSON (msgs secureEmergencyNoEnable));
    "control(checker): the helpers reject a wrong expectation" =
      chk (failingCount outsideImperm == 1 && failingCount grubForced == 1 && failingCount enabled != 1 && confValue enabled != confFor customBundle)
        "failingCount/confValue accepted a wrong expectation";
  };

  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
{
  checks = lib.mapAttrs (_: guard) checks;
  bundles = { default = defaultBundle; custom = customBundle; };
  etcSource = {
    default = (etc enabled)."sbctl/sbctl.conf".source;
    custom = (etc custom)."sbctl/sbctl.conf".source;
  };
}
