let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

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

  sweepsToml = cfg: cfg.config.home-manager.users.krit.xdg.configFile."nix-sweep/presets.toml".text;
  sweepsParsed = cfg: builtins.fromTOML (sweepsToml cfg);

  perHost = name: cfg: {
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
    "check-${name}-nix-sweeps-toml" =
      let t = sweepsParsed cfg; gcn = cfg.config.myconfig.nix-sweeps.gcn; in
      failIf (
        (lib.optional (!builtins.isInt t.default.keep-min) "default.keep-min is not an int")
        ++ (lib.optional (!builtins.isInt t.ask.keep-min) "ask.keep-min is not an int")
        ++ (lib.optional (toString t.default.keep-min != gcn) "default.keep-min != gcn (${gcn})")
        ++ (lib.optional (t.default.interactive != false) "default.interactive must be false")
        ++ (lib.optional (t.ask.interactive != true) "ask.interactive must be true")
        ++ (lib.optional (t.default.remove-older != cfg.config.myconfig.nix-sweeps.gcd) "default.remove-older != gcd")
        ++ (lib.optional (t.ask.remove-older != cfg.config.myconfig.nix-sweeps.gcd) "ask.remove-older != gcd")
      );
  };

  nixosOnly = name: cfg: {
    "check-${name}-cachix-pairing-and-priority" =
      let
        s = (nixSettings cfg);
        c = cfg.config.myconfig.cachix;
        want = "https://${c.name}.cachix.org?priority=20";
      in
      if builtins.elem want s.substituters && builtins.elem c.publicKey s.trusted-public-keys
        && lib.hasPrefix "${c.name}.cachix.org-1:" c.publicKey then ok
      else "FAIL: cachix settings: substituters=${builtins.toJSON s.substituters} trusted-public-keys=${builtins.toJSON s.trusted-public-keys}";
    "check-${name}-nh-flake" = eq "programs.nh.flake" cfg.config.programs.nh.flake "/home/krit/nix";
    "check-${name}-gc-exclusive-with-nh-clean" =
      let r = { nixGc = cfg.config.nix.gc.automatic; nhClean = cfg.config.programs.nh.clean.enable; }; in
      eq "nix.gc.automatic / nh.clean.enable" r { nixGc = false; nhClean = true; };
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

  controls = {
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
      let c = withModules desktop [{ myconfig.nix-sweeps.gcn = lib.mkForce "\"3\""; }];
      in eq "keep-min isInt when gcn is quoted" (builtins.isInt (sweepsParsed c).default.keep-min) false;
    "check-control-sweeps-gcn-tracks-option" =
      let c = withModules desktop [{ myconfig.nix-sweeps.gcn = lib.mkForce "7"; }];
      in eq "default.keep-min with gcn=7" (sweepsParsed c).default.keep-min 7;
  };
in
lib.foldl' (a: b: a // b) { } (
  lib.mapAttrsToList perHost hosts
  ++ [ (nixosOnly "nixos-desktop" hosts.nixos-desktop) (nixosOnly "nixos-laptop" hosts.nixos-laptop) darwinOnly controls ]
)
