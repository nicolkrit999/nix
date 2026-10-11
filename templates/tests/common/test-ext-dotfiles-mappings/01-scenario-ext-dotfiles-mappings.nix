let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  nixosFile = flakeRoot + "/users/krit/nixos/services/ext-dotfiles-private.nix";
  darwinFile = flakeRoot + "/users/krit/darwin/services/ext-dotfiles-private.nix";

  loadData = file:
    let
      text = builtins.readFile file;
      afterLet = lib.concatStringsSep "\nlet\n" (builtins.tail (lib.splitString "\nlet\n" text));
      body = builtins.head (lib.splitString "\nin\n" afterLet);
    in
    import (builtins.toFile "ext-dotfiles-data.nix" ''
      let
      ${body}
      in { inherit packageLeaves packagesPerHost extraMappingsPerHost syncBack; }
    '');

  nixosData = loadData nixosFile;
  darwinData = loadData darwinFile;

  nixosCfg = name: flake.nixosConfigurations.${name}.config;
  darwinCfg = flake.darwinConfigurations.Krits-MacBook-Pro.config;
  nasCfg = flake.homeConfigurations."krit@Nicol-NAS".config;

  hosts = {
    desktop = rec {
      data = nixosData;
      c = nixosCfg "nixos-desktop";
      hm = c.home-manager.users.krit.home;
      homeDir = "/home/krit";
      schoolPrefix = ".school-workspace/";
    };
    laptop = rec {
      data = nixosData;
      c = nixosCfg "nixos-laptop";
      hm = c.home-manager.users.krit.home;
      homeDir = "/home/krit";
      schoolPrefix = ".school-workspace/";
    };
    nas = rec {
      data = nixosData;
      c = nasCfg;
      hm = c.home;
      homeDir = "/home/krit";
      schoolPrefix = null;
    };
    mac = rec {
      data = darwinData;
      c = darwinCfg;
      hm = c.home-manager.users.krit.home;
      homeDir = "/Users/krit";
      schoolPrefix = "school-workspace/";
    };
  };

  ok = "ok";
  fail = msg: "FAIL: ${msg}";
  verdict = msgs: if msgs == [ ] then ok else fail (lib.concatStringsSep "; " msgs);
  eq = what: got: want:
    if got == want then ok
    else fail "${what} = ${builtins.toJSON got}, expected ${builtins.toJSON want}";

  hostname = h: h.c.myconfig.constants.hostname;
  enabledPackages = h: h.data.packagesPerHost.${hostname h} or [ ];
  leavesOf = h: lib.concatMap (p: h.data.packageLeaves.${p}) (enabledPackages h);
  extraOf = h: h.data.extraMappingsPerHost.${hostname h} or { };
  mappingsOf = h:
    lib.foldl' (acc: p: acc // lib.listToAttrs (map (l: { name = l; value = "${p}/${l}"; }) h.data.packageLeaves.${p}))
      { }
      (enabledPackages h) // extraOf h;
  expectedSyncBack = h: lib.filter (p: (mappingsOf h) ? ${p}) h.data.syncBack;

  duplicates = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);
  packageOverlap = data: hostPkgs:
    let
      leaves = lib.concatMap (p: map (l: { inherit p l; }) data.${p}) hostPkgs;
      names = map (x: x.l) leaves;
    in
    map (d: "${d} in ${lib.concatStringsSep "+" (map (x: x.p) (lib.filter (x: x.l == d) leaves))}") (duplicates names);
  intersect = a: b: lib.filter (x: builtins.elem x b) a;

  uniqueCheck = h:
    verdict (map (d: "leaf in two packages: ${d}") (duplicates (leavesOf h)));
  disjointCheck = h:
    verdict (map (k: "extraMappings key also a package leaf: ${k}") (intersect (builtins.attrNames (extraOf h)) (leavesOf h)));
  hostKnownCheck = h:
    if enabledPackages h == [ ] then fail "hostname ${hostname h} has no packagesPerHost entry (silent no-op)" else ok;
  packagesExistCheck = h:
    verdict (map (p: "package ${p} missing from packageLeaves") (lib.filter (p: !(h.data.packageLeaves ? ${p})) (enabledPackages h)));

  linkCheck = h:
    let
      files = h.hm.file;
      m = mappingsOf h;
      bad = lib.concatMap
        (k:
          if !(files ? ${k}) then [ "home.file lacks ${k}" ]
          else
            let want = "ln -s ${h.homeDir}/dotfiles-private/${m.${k}} $out"; in
            (lib.optional (files.${k}.source.buildCommand != want) "${k} links ${files.${k}.source.buildCommand}, expected ${want}")
            ++ (lib.optional (files.${k}.force != true) "${k} not force"))
        (builtins.attrNames m);
    in
    if m == { } then fail "no mappings at all" else verdict bad;

  syncBackCalls = h:
    lib.filter (l: lib.hasPrefix "sync_back " l) (lib.splitString "\n" h.hm.activation.syncBackDotfilesPrivate.data);
  syncBackCheck = h:
    eq "sync_back calls" (syncBackCalls h)
      (map (p: "sync_back ${lib.escapeShellArg p} ${lib.escapeShellArg (mappingsOf h).${p}}") (expectedSyncBack h));
  syncBackNonEmpty = h:
    if expectedSyncBack h == [ ] then fail "no syncBack path active on this host" else ok;

  syncBackKnownCheck = data:
    let leaves = lib.concatLists (builtins.attrValues data.packageLeaves);
    in verdict (map (p: "syncBack path ${p} is not a leaf of any package") (lib.filter (p: !(builtins.elem p leaves)) data.syncBack));

  keysKnownCheck = data: realHosts:
    verdict (
      map (k: "packagesPerHost key ${k} is not a real host") (lib.filter (k: !(builtins.elem k realHosts)) (builtins.attrNames data.packagesPerHost))
      ++ map (k: "extraMappingsPerHost key ${k} is not a real host") (lib.filter (k: !(builtins.elem k realHosts)) (builtins.attrNames data.extraMappingsPerHost))
    );

  unusedCheck = data: pkgsLists:
    let used = lib.unique (lib.concatLists pkgsLists);
    in verdict (map (p: "package ${p} defined but used by no host") (lib.filter (p: !(builtins.elem p used)) (builtins.attrNames data.packageLeaves)));

  schoolCheck = h:
    let
      keys = builtins.attrNames (h.hm.file);
      school = lib.filter (k: lib.hasInfix "school-workspace" k) keys;
      bad = lib.filter (k: !(lib.hasPrefix h.schoolPrefix k)) school;
    in
    if school == [ ] then fail "no school-workspace link in home.file"
    else verdict (map (k: "wrong school-workspace prefix: ${k}") bad);

  allPkgs = hs: map enabledPackages hs;
  nixosHosts = [ hosts.desktop hosts.laptop hosts.nas ];

  perHost = name: h: {
    "check-${name}-leaves-unique" = uniqueCheck h;
    "check-${name}-extra-disjoint" = disjointCheck h;
    "check-${name}-hostname-known" = hostKnownCheck h;
    "check-${name}-packages-exist" = packagesExistCheck h;
    "check-${name}-links" = linkCheck h;
    "check-${name}-syncback-calls" = syncBackCheck h;
  };

  fake = { a = [ "x" "y" ]; b = [ "y" "z" ]; };
in
perHost "desktop" hosts.desktop
// perHost "laptop" hosts.laptop
// perHost "nas" hosts.nas
// perHost "mac" hosts.mac
  // {
  "check-desktop-syncback-nonempty" = syncBackNonEmpty hosts.desktop;
  "check-laptop-syncback-nonempty" = syncBackNonEmpty hosts.laptop;
  "check-mac-syncback-nonempty" = syncBackNonEmpty hosts.mac;

  "check-nixos-syncback-known" = syncBackKnownCheck nixosData;
  "check-darwin-syncback-known" = syncBackKnownCheck darwinData;

  "check-nixos-host-keys-real" = keysKnownCheck nixosData (map hostname nixosHosts);
  "check-darwin-host-keys-real" = keysKnownCheck darwinData [ (hostname hosts.mac) ];

  "check-nixos-no-unused-package" = unusedCheck nixosData (allPkgs nixosHosts);
  "check-darwin-no-unused-package" = unusedCheck darwinData (allPkgs [ hosts.mac ]);

  "check-desktop-school-dot" = schoolCheck hosts.desktop;
  "check-laptop-school-dot" = schoolCheck hosts.laptop;
  "check-mac-school-nodot" = schoolCheck hosts.mac;
  "check-nas-no-school" = verdict (map (k: "unexpected ${k}") (lib.filter (k: lib.hasInfix "school-workspace" k) (builtins.attrNames hosts.nas.hm.file)));

  "check-control-overlap-detected" = eq "overlap detector" (packageOverlap fake [ "a" "b" ]) [ "y in a+b" ];
  "check-control-overlap-clean" = eq "overlap detector on disjoint" (packageOverlap fake [ "a" ]) [ ];
  "check-control-typo-host-detected" =
    eq "typo host" (hostKnownCheck (hosts.desktop // { c = { myconfig.constants.hostname = "nixos-desktpo"; }; })) (fail "hostname nixos-desktpo has no packagesPerHost entry (silent no-op)");
}
