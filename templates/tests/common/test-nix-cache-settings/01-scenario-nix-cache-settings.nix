let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  fx = import ../../lib/fixture-host.nix flake;

  nixosCfg = name: flake.nixosConfigurations.${name};
  darwinCfg = flake.darwinConfigurations.Krits-MacBook-Pro;

  hosts = {
    nixos-desktop = nixosCfg "nixos-desktop";
    nixos-laptop = nixosCfg "nixos-laptop";
    darwin = darwinCfg;
  };

  ok = "ok";
  eq = what: got: want:
    if got == want then ok
    else "FAIL: ${what} = ${builtins.toJSON got}, expected ${builtins.toJSON want}";
  failIf = problems:
    if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " problems}";

  urlHost = url:
    let
      noScheme = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      authority = lib.head (lib.splitString "/" noScheme);
      noQuery = lib.head (lib.splitString "?" authority);
    in
    lib.head (lib.splitString ":" noQuery);

  nixSettings = cfg: cfg.config.nix.settings;
  substituters = cfg: (nixSettings cfg).substituters or [ ] ++ (nixSettings cfg).extra-substituters or [ ];
  trustedKeys = cfg: (nixSettings cfg).trusted-public-keys or [ ] ++ (nixSettings cfg).extra-trusted-public-keys or [ ];

  expectedKeyPrefix = cfg: url:
    let
      host = urlHost url;
      attic = cfg.config.myconfig.attic;
    in
    if attic.enable && lib.hasPrefix attic.serverUrl url then "${attic.cacheName}:"
    else if host == "cache.nixos.org" || lib.hasSuffix ".cachix.org" host then "${host}-1:"
    else null;

  pairingProblems = cfg:
    let keys = trustedKeys cfg; in
    lib.concatMap
      (url:
        let p = expectedKeyPrefix cfg url; in
        if p == null then [ "no pairing rule for substituter ${url}" ]
        else if builtins.any (k: lib.hasPrefix p k) keys then [ ]
        else [ "substituter ${url} has no trusted key starting with ${p}" ])
      (substituters cfg);

  withModules = cfg: modules: cfg.extendModules { inherit modules; };

  failedAssertions = cfg: map (a: a.message) (builtins.filter (a: !a.assertion) cfg.config.assertions);
  anyMsg = needle: msgs: builtins.any (m: lib.hasInfix needle m) msgs;

  netrcOf = cfg: cfg.config.sops.templates."attic-netrc".content;

  sweepsOn = modules: fx.mkNixos ([{ myconfig.nix-sweeps.enable = lib.mkForce true; }] ++ modules);
  sweepsToml = cfg: (fx.hmOf cfg).xdg.configFile."nix-sweep/presets.toml".text;
  sweepsParsed = cfg: builtins.fromTOML (sweepsToml cfg);

  userOf = cfg: cfg.config.myconfig.constants.user;
  hmOf = cfg: cfg.config.home-manager.users.${userOf cfg};
  aliasesOf = cfg: (hmOf cfg).home.shellAliases;

  pushGatingProblems = cfg:
    let
      my = cfg.config.myconfig;
      a = aliasesOf cfg;
      want = {
        attic = my.attic.enable && my.attic.push;
        cachix = my.cachix.enable && my.cachix.push;
      };
      marker = { attic = "attic push "; cachix = "cachix push "; };
      inAlias = alias: tool:
        lib.optional (lib.hasInfix marker.${tool} a.${alias} != want.${tool})
          "${alias} ${if want.${tool} then "lacks" else "has"} the ${tool} push command (enable && push = ${lib.boolToString want.${tool}})";
      pushAlias = tool:
        lib.optional ((a ? "${tool}-push") != want.${tool})
          "${tool}-push alias ${if want.${tool} then "missing" else "present"} (enable && push = ${lib.boolToString want.${tool}})";
    in
    lib.concatMap (alias: if a ? ${alias} then inAlias alias "attic" ++ inAlias alias "cachix" else [ "alias ${alias} missing" ]) [ "sw" "upd" ]
    ++ pushAlias "attic" ++ pushAlias "cachix";

  atticConfigFile = "attic/config.toml";
  atticConfigProblems = cfg:
    let
      at = cfg.config.myconfig.attic;
      files = (hmOf cfg).xdg.configFile;
      want = at.enable && at.push;
      server = files.${atticConfigFile}.source.value.servers.nas-push or null;
    in
    if (files.${atticConfigFile}.enable or false) != want then
      [ "${atticConfigFile} ${if want then "missing" else "present"} (attic enable && push = ${lib.boolToString want})" ]
    else if !want then [ ]
    else if server == null then [ "${atticConfigFile} has no servers.nas-push" ]
    else
      lib.optional (builtins.attrNames server != [ "endpoint" "token-file" ])
        "nas-push keys are ${builtins.toJSON (builtins.attrNames server)}, expected only endpoint and token-file"
      ++ lib.optional ((server.token-file or null) != at.authTokenPath) "nas-push token-file is not attic.authTokenPath"
      ++ lib.optional ((server.endpoint or null) != at.serverUrl) "nas-push endpoint is not attic.serverUrl";

  tokenArgvProblems = cfg:
    let
      a = aliasesOf cfg;
      c = cfg.config.myconfig.cachix;
      count = needle: hay: builtins.length (lib.splitString needle hay) - 1;
      safeCachix = "CACHIX_AUTH_TOKEN=\"$(cat ${c.authTokenPath})\" cachix push ";
      offenders = needle: builtins.filter (n: lib.hasInfix needle a.${n}) (builtins.attrNames a);
    in
    map (n: "alias ${n} runs attic login") (offenders "attic login")
    ++ map (n: "alias ${n} passes CACHIX_AUTH_TOKEN through env argv") (offenders "env CACHIX_AUTH_TOKEN=")
    ++ lib.optionals (c.enable && c.push && c.authTokenPath != "")
      (map (n: "alias ${n} runs cachix push without the CACHIX_AUTH_TOKEN=\"$(cat <authTokenPath>)\" prefix")
        (builtins.filter (n: count "cachix push " a.${n} != count safeCachix a.${n}) (offenders "cachix push ")))
    ++ atticConfigProblems cfg;

  presetsFile = "nix-sweep/presets.toml";
  isSweep = p: lib.getName p == "nix-sweep";
  sweepInstalledProblems = label: hmCfg: extraPkgs:
    if !(hmCfg.xdg.configFile ? ${presetsFile}) then [ ]
    else if builtins.any isSweep (hmCfg.home.packages ++ extraPkgs) then [ ]
    else [ "${label}: ${presetsFile} is generated but nix-sweep is not installed" ];
  systemSweepProblems = name: cfg: sweepInstalledProblems name (hmOf cfg) cfg.config.environment.systemPackages;
  homeSweepProblems = name: home: sweepInstalledProblems name home.config [ ];

  homes = flake.homeConfigurations;
  sweepsHome = homes."krit@template-host-minimal".extendModules { modules = [{ myconfig.nix-sweeps.enable = lib.mkForce true; }]; };

  sweepsChecks =
    let
      fxOn = sweepsOn [ ];
      fxOff = fx.mkNixos [{ myconfig.nix-sweeps.enable = lib.mkForce false; }];
      t = sweepsParsed fxOn;
      gcn = fxOn.config.myconfig.nix-sweeps.gcn;
      gcd = fxOn.config.myconfig.nix-sweeps.gcd;
    in
    {
      "check-sweeps-toml" = failIf (
        (lib.optional (!builtins.isInt t.default.keep-min) "default.keep-min is not an int")
        ++ (lib.optional (!builtins.isInt t.ask.keep-min) "ask.keep-min is not an int")
        ++ (lib.optional (toString t.default.keep-min != gcn) "default.keep-min != gcn (${gcn})")
        ++ (lib.optional (t.default.interactive != false) "default.interactive must be false")
        ++ (lib.optional (t.ask.interactive != true) "ask.interactive must be true")
        ++ (lib.optional (t.default.remove-older != gcd) "default.remove-older != gcd")
        ++ (lib.optional (t.ask.remove-older != gcd) "ask.remove-older != gcd")
      );
      "check-sweeps-nix-sweep-installed" = failIf (
        (if (fx.hmOf fxOn).xdg.configFile ? ${presetsFile} then [ ] else [ "${presetsFile} not generated with nix-sweeps enabled" ])
        ++ systemSweepProblems "sweeps-fixture" fxOn
      );
      "check-sweeps-disabled-no-presets" =
        if (fx.hmOf fxOff).xdg.configFile ? ${presetsFile} then "FAIL: ${presetsFile} generated with nix-sweeps disabled"
        else if builtins.any isSweep fxOff.config.environment.systemPackages then "FAIL: nix-sweep installed with nix-sweeps disabled"
        else ok;
    };

  perHost = name: cfg: {
    "check-${name}-push-alias-gating" = failIf (pushGatingProblems cfg);
    "check-${name}-push-token-off-argv" = failIf (tokenArgvProblems cfg);
    "check-${name}-substituter-key-pairing" = failIf (pairingProblems cfg);
    "check-${name}-substituter-nonempty" =
      if builtins.length (substituters cfg) >= 2 then ok
      else "FAIL: ${name} has fewer than 2 substituters: ${builtins.toJSON (substituters cfg)}";
    "check-${name}-no-connect-timeout" =
      failIf (builtins.filter (u: lib.hasInfix "connect-timeout" u) (substituters cfg));
    "check-${name}-attic-priority" =
      let a = builtins.filter (u: lib.hasPrefix cfg.config.myconfig.attic.serverUrl u) (substituters cfg);
      in if builtins.length a == 1 && lib.hasSuffix "?priority=10" (builtins.head a) then ok
      else "FAIL: expected exactly one attic substituter with ?priority=10, got ${builtins.toJSON a}";
    "check-${name}-attic-key-prefix" =
      let a = cfg.config.myconfig.attic; in
      eq "attic publicKey prefix" (lib.hasPrefix "${a.cacheName}:" a.publicKey) true;
    "check-${name}-attic-netrc-host" =
      let c = netrcOf cfg; in
      if lib.hasInfix "machine nicol-nas.tail9b9ae8.ts.net password " c && !(lib.hasInfix ":8081" c) then ok
      else "FAIL: netrc content unexpected (host with port stripped expected): ${builtins.head (lib.splitString "password" c)}";
    "check-${name}-attic-netrc-file-set" =
      eq "nix.settings.netrc-file" (nixSettings cfg).netrc-file cfg.config.sops.templates."attic-netrc".path;
  };

  nixosOnly = name: cfg: {
    "check-${name}-cachix-pairing-and-priority" =
      let
        s = nixSettings cfg;
        c = cfg.config.myconfig.cachix;
        want = "https://${c.name}.cachix.org?priority=20";
      in
      if builtins.elem want s.substituters && builtins.elem c.publicKey s.trusted-public-keys
        && lib.hasPrefix "${c.name}.cachix.org-1:" c.publicKey then ok
      else "FAIL: cachix settings: substituters=${builtins.toJSON s.substituters} trusted-public-keys=${builtins.toJSON s.trusted-public-keys}";
    "check-${name}-no-cosmic-cachix" = failIf (cosmicCacheProblems cfg);
    "check-${name}-nh-flake" = eq "programs.nh.flake" cfg.config.programs.nh.flake "/home/krit/nix";
    "check-${name}-gc-exclusive-with-nh-clean" =
      let r = { nixGc = cfg.config.nix.gc.automatic; nhClean = cfg.config.programs.nh.clean.enable; }; in
      eq "nix.gc.automatic / nh.clean.enable" r { nixGc = false; nhClean = true; };
  };

  cosmicCacheHost = "cosmic.cachix.org";
  cosmicCacheProblems = cfg:
    map (u: "substituter ${u}") (builtins.filter (u: urlHost u == cosmicCacheHost) (substituters cfg))
    ++ map (k: "trusted key ${builtins.substring 0 20 k}") (builtins.filter (k: lib.hasPrefix "${cosmicCacheHost}-" k) (trustedKeys cfg));
  srcText = rel: builtins.readFile "${flake.outPath}/${rel}";
  cosmicCacheSources = [ "modules/nixos/toplevel/nix-nixos.nix" ".github/workflows/build.yml" ];
  cosmicCacheChecks = {
    "check-no-cosmic-cachix-in-sources" =
      failIf (map (f: "${f} mentions ${cosmicCacheHost}") (builtins.filter (f: lib.hasInfix cosmicCacheHost (srcText f)) cosmicCacheSources));
    "check-control-cosmic-cachix-sources-readable" =
      failIf (map (f: "${f} has no cachix substituter lines, the source scan would be vacuous") (builtins.filter (f: !(lib.hasInfix "hyprland.cachix.org" (srcText f))) cosmicCacheSources));
    "check-control-cosmic-cachix-detected" =
      let
        c = withModules desktop [{
          nix.settings.extra-substituters = [ "https://${cosmicCacheHost}" ];
          nix.settings.extra-trusted-public-keys = [ "${cosmicCacheHost}-1:AAAA=" ];
        }];
      in
      if builtins.length (cosmicCacheProblems c) == 2 then ok
      else "FAIL: mutant cosmic cache not detected: ${builtins.toJSON (cosmicCacheProblems c)}";
  };

  darwinOnly = {
    "check-darwin-nh-flake" =
      eq "HM programs.nh.flake" darwinCfg.config.home-manager.users.krit.programs.nh.flake "/Users/krit/nix";
    "check-darwin-nh-clean" =
      eq "HM programs.nh.clean.enable" darwinCfg.config.home-manager.users.krit.programs.nh.clean.enable true;
  };

  desktop = hosts.nixos-desktop;
  atticOn = extra: withModules desktop [{ myconfig.attic = extra; }];
  forced = lib.mapAttrs (_: lib.mkForce);

  homeChecks = {
    "check-homes-nix-sweep-installed" = failIf (lib.concatLists (lib.mapAttrsToList homeSweepProblems homes));
    "check-homes-presets-nonempty" =
      if homes == { } then ok
      else if sweepsHome.config.xdg.configFile ? ${presetsFile} then ok
      else "FAIL: ${presetsFile} not generated by a standalone home with nix-sweeps on, the homes install check would run over nothing";
  };

  pushOn = attic: cachix: withModules desktop [{
    myconfig.attic = forced { inherit (attic) enable push; };
    myconfig.cachix = forced { inherit (cachix) enable push; };
  }];
  pushFlags = enable: push: { inherit enable push; };
  dropSweep = pkgs: builtins.filter (p: !(isSweep p)) pkgs;

  controls = {
    "check-control-push-both-on" =
      let c = pushOn (pushFlags true true) (pushFlags true true);
      in failIf (pushGatingProblems c ++ tokenArgvProblems c ++ lib.optional (!((aliasesOf c) ? attic-push && (aliasesOf c) ? cachix-push)) "push aliases missing with both push on");
    "check-control-push-attic-off" =
      let c = pushOn (pushFlags true false) (pushFlags true true);
      in failIf (pushGatingProblems c ++ tokenArgvProblems c ++ lib.optional (lib.hasInfix "attic push " (aliasesOf c).sw) "sw still pushes to attic");
    "check-control-push-cachix-off" =
      let c = pushOn (pushFlags true true) (pushFlags true false);
      in failIf (pushGatingProblems c ++ tokenArgvProblems c ++ lib.optional (lib.hasInfix "cachix push " (aliasesOf c).upd) "upd still pushes to cachix");
    "check-control-push-cachix-disabled-push-true" =
      let c = pushOn (pushFlags true true) (pushFlags false true);
      in failIf (pushGatingProblems c ++ tokenArgvProblems c ++ lib.optional ((aliasesOf c) ? cachix-push) "cachix-push alias with cachix disabled");
    "check-control-push-both-off" =
      let c = pushOn (pushFlags true false) (pushFlags true false);
      in failIf (pushGatingProblems c ++ tokenArgvProblems c ++ lib.optional ((aliasesOf c).sw != (aliasesOf (pushOn (pushFlags false false) (pushFlags false false))).sw) "sw with push off differs from sw with both caches disabled");
    "check-control-token-argv-detected" =
      let
        c = withModules desktop [{
          home-manager.users.krit.home.shellAliases = {
            sw = lib.mkForce "attic login nas-push http://attic.example \"$(cat /run/test-token)\"";
            upd = lib.mkForce "nix path-info -r /run/current-system | env CACHIX_AUTH_TOKEN=$(cat /run/test-token) cachix push x";
            cachix-push = lib.mkForce "nix path-info -r /run/current-system | cachix push x";
          };
        }];
        p = tokenArgvProblems c;
        hit = alias: what: builtins.any (m: lib.hasPrefix "alias ${alias} ${what}" m) p;
      in
      if hit "sw" "runs attic login" && hit "upd" "passes CACHIX_AUTH_TOKEN" && hit "cachix-push" "runs cachix push without" then ok
      else "FAIL: mutant token-on-argv aliases not all detected: ${builtins.toJSON p}";
    "check-control-attic-config-token-detected" =
      let
        c = withModules desktop [
          ({ pkgs, ... }: {
            home-manager.users.krit.xdg.configFile.${atticConfigFile}.source = lib.mkForce ((pkgs.formats.toml { }).generate "attic-config.toml" {
              servers.nas-push = { endpoint = desktop.config.myconfig.attic.serverUrl; token = "not-a-real-token"; };
            });
          })
        ];
      in
      if builtins.length (atticConfigProblems c) == 2 then ok
      else "FAIL: inline attic token not detected: ${builtins.toJSON (atticConfigProblems c)}";
    "check-control-nix-sweep-missing-detected" =
      let
        base = sweepsOn [ ];
        c = sweepsOn [{ environment.systemPackages = lib.mkForce (dropSweep base.config.environment.systemPackages); }];
      in
      if systemSweepProblems "fixture-mutant" c != [ ] then ok else "FAIL: removing nix-sweep from systemPackages was not detected";
    "check-control-home-nix-sweep-missing-detected" =
      if homes == { } then ok
      else
        let h = sweepsHome.extendModules { modules = [{ home.packages = lib.mkForce (dropSweep sweepsHome.config.home.packages); }]; };
        in if homeSweepProblems "home-mutant" h != [ ] then ok else "FAIL: removing nix-sweep from home.packages was not detected";
    "check-control-wrong-key-detected" =
      let c = withModules desktop [{ myconfig.cachix.publicKey = lib.mkForce "someone-else.cachix.org-1:AAAA="; myconfig.attic.publicKey = lib.mkForce "wrong:AAAA="; }];
      in
      if builtins.length (pairingProblems c) >= 1 then ok
      else "FAIL: pairing check did not flag a mismatched attic key";
    "check-control-attic-netrc-port-stripped" =
      let c = atticOn (forced { serverUrl = "https://attic.example:8443"; });
      in
      if lib.hasInfix "machine attic.example password " (netrcOf c) && !(lib.hasInfix "8443" (netrcOf c)) then ok
      else "FAIL: netrc for https://attic.example:8443: ${netrcOf c}";
    "check-control-attic-netrc-path-stripped" =
      let c = atticOn (forced { serverUrl = "https://attic.example/sub/path"; });
      in
      if lib.hasInfix "machine attic.example password " (netrcOf c) then ok
      else "FAIL: netrc for URL with path: ${netrcOf c}";
    "check-control-attic-empty-url-asserts" =
      let m = failedAssertions (atticOn (forced { serverUrl = ""; }));
      in
      if anyMsg "serverUrl/cacheName/publicKey" m then ok
      else "FAIL: expected the serverUrl/cacheName/publicKey assertion, got ${builtins.toJSON m}";
    "check-control-attic-missing-secret-asserts" =
      let m = failedAssertions (atticOn (forced { authTokenPath = "/run/secrets/no-such-attic-token"; }));
      in
      if anyMsg "no-such-attic-token" m then ok
      else "FAIL: expected the missing sops secret assertion, got ${builtins.toJSON m}";
    "check-control-real-hosts-no-failed-attic-assertions" =
      let m = lib.concatMap failedAssertions (builtins.attrValues hosts);
      in
      if !(anyMsg "attic" m) then ok else "FAIL: attic assertions fail on real hosts: ${builtins.toJSON m}";
    "check-control-sweeps-quoted-gcn-not-int" =
      let c = sweepsOn [{ myconfig.nix-sweeps.gcn = lib.mkForce "\"3\""; }];
      in eq "keep-min isInt when gcn is quoted" (builtins.isInt (sweepsParsed c).default.keep-min) false;
    "check-control-sweeps-gcn-tracks-option" =
      let c = sweepsOn [{ myconfig.nix-sweeps.gcn = lib.mkForce "7"; }];
      in eq "default.keep-min with gcn=7" (sweepsParsed c).default.keep-min 7;
  };
in
lib.foldl' (a: b: a // b) { } (
  lib.mapAttrsToList perHost hosts
  ++ [ sweepsChecks (nixosOnly "nixos-desktop" hosts.nixos-desktop) (nixosOnly "nixos-laptop" hosts.nixos-laptop) darwinOnly homeChecks cosmicCacheChecks controls ]
)
