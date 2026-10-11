let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  variant = sys.extendModules {
    modules = [{ myconfig.services.impermanence.enable = lib.mkForce false; }];
  };

  scriptNames = [ "snap-lock" "snap-unlock" "snap-create-home" "snap-create-root" "_snap-create" ];
  hmPkgs = c: c.config.home-manager.users.${c.config.myconfig.constants.user}.home.packages;
  scriptText = c: n:
    let m = lib.filter (p: (p.name or "") == n) (hmPkgs c);
    in if m == [ ] then null else (lib.head m).text or null;
  textOrEmpty = c: n: let t = scriptText c n; in if t == null then "" else t;

  nonEmptyStr = x: x != null && x != "";
  literals = text:
    let
      grab = re: lib.concatMap (m: if builtins.isList m then m else [ ]) (builtins.split re text);
    in
    grab ''snapper -c "?([a-z]+)"?[ ]''
    ++ grab ''CFG="([a-z]+)"''
    ++ grab ''_snap-create ([a-z]+)'';

  ok = "ok";
  verdict = bad: if bad == [ ] then ok else "FAIL: " + lib.concatStringsSep "; " bad;
  line = label: bad: "${label}\t${verdict bad}\n";

  checksFor = tag: c: expectKeys: expectSubvol: expectSnapDir:
    let
      cfgs = c.config.services.snapper.configs;
      keys = lib.sort (a: b: a < b) (lib.attrNames cfgs);
      rootKey = lib.head (lib.filter (k: k != "home") (lib.attrNames cfgs) ++ [ "<none>" ]);
      user = c.config.myconfig.constants.user;
      limits = [ "HOURLY" "DAILY" "WEEKLY" "MONTHLY" "YEARLY" ];
      badLimits = lib.concatMap
        (k: lib.concatMap
          (l:
            let v = cfgs.${k}."TIMELINE_LIMIT_${l}" or null;
            in lib.optional (!(builtins.isString v && builtins.match "[0-9]+" v != null)) "${k}.${l}=${toString v}")
          limits)
        (lib.attrNames cfgs);
      act = c.config.system.activationScripts.createSnapperHome.text or "";
      names = map (p: p.name or "") (hmPkgs c);
      missing = lib.filter (n: !(lib.elem n names)) (lib.filter (n: n != "_snap-create") scriptNames);
      perScript = lib.concatMap
        (n:
          let
            lits = lib.unique (literals (textOrEmpty c n));
            unknown = lib.filter (l: !(cfgs ? ${l})) lits;
          in
          lib.optional (unknown != [ ]) "${n} names ${lib.concatStringsSep "," unknown}")
        (lib.filter (n: n != "_snap-create") scriptNames);
    in
    line "${tag}: snapper config keys are ${lib.concatStringsSep "+" expectKeys}" (lib.optional (keys != expectKeys) "keys=[${lib.concatStringsSep "," keys}]")
    + line "${tag}: root-side config SUBVOLUME is ${expectSubvol}" (lib.optional ((cfgs.${rootKey}.SUBVOLUME or null) != expectSubvol) "got ${toString (cfgs.${rootKey}.SUBVOLUME or null)}")
    + line "${tag}: ALLOW_USERS is the configured user only" (lib.concatMap (k: lib.optional ((cfgs.${k}.ALLOW_USERS or null) != [ user ]) "${k}=${builtins.toJSON (cfgs.${k}.ALLOW_USERS or null)}") (lib.attrNames cfgs))
    + line "${tag}: TIMELINE_LIMIT_* values are numeric strings" badLimits
    + line "${tag}: activation creates ${expectSnapDir}" (lib.optional (!(lib.hasInfix "btrfs subvolume create ${expectSnapDir}\n" (act + "\n"))) "not found in activation text")
    + line "${tag}: HM installs the four snap-* helper scripts" (map (n: "missing ${n}") missing)
    + line "${tag}: script literals (snapper -c / CFG= / _snap-create) name existing snapper configs" perScript
    + line "${tag}: scripts have non-empty text" (lib.concatMap (n: lib.optional (!(nonEmptyStr (scriptText c n))) "${n} has no text") (lib.filter (n: n != "_snap-create") scriptNames));
in
{
  report =
    checksFor "base" sys [ "home" "persist" ] "/persist" "/persist/.snapshots"
    + checksFor "impermanence-off" variant [ "home" "root" ] "/" "/.snapshots";

  scripts = builtins.toJSON (lib.genAttrs (lib.filter (n: n != "_snap-create") scriptNames) (n: textOrEmpty sys n));
}
