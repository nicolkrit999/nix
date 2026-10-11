let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  darwinHostNames = [ "Krits-MacBook-Pro" ];
  homeOnlyHostNames = [ "Nicol-NAS" ];

  lock = builtins.fromJSON (builtins.readFile "${flakeRoot}/flake.lock");
  flakeNixText = builtins.readFile "${flakeRoot}/flake.nix";

  probe = host: _hmUser:
    let
      x = host.extendModules {
        modules = [
          ({ pkgs, pkgsStable, pkgsStableFor, ... }: {
            environment.etc."probe-system".text = pkgs.stdenv.hostPlatform.system;
            environment.etc."probe-has-entry".text = lib.boolToString (pkgsStableFor ? ${pkgs.stdenv.hostPlatform.system});
            environment.etc."probe-version".text = toString pkgsStable.path;
          })
        ];
      };
    in
    {
      system = x.config.environment.etc."probe-system".text;
      hasEntry = x.config.environment.etc."probe-has-entry".text;
      version = x.config.environment.etc."probe-version".text;
    };

  stableVersion = flake.inputs.nixpkgs-stable.lib.version;
  stablePath = toString flake.inputs.nixpkgs-stable;

  probeCheck = name: host:
    let p = probe host "krit"; in
    if p.hasEntry != "true" then "FAIL: ${name}: pkgsStableFor has no entry for ${p.system}"
    else if p.version != stablePath then "FAIL: ${name}: pkgsStable.path ${p.version} != nixpkgs-stable input ${stablePath}"
    else "ok";

  rootDefs = host:
    builtins.length (builtins.filter (d: d.value ? "/") host.options.fileSystems.definitionsWithLocations);

  stableRootNode = lock.nodes.root.inputs.nixpkgs-stable;
  stableLock = if builtins.isString stableRootNode then lock.nodes.${stableRootNode}.original else { };
in
{
  check-nas-not-in-nixos = guard (
    let leaked = builtins.filter (n: builtins.elem n (builtins.attrNames flake.nixosConfigurations)) (homeOnlyHostNames ++ darwinHostNames);
    in expect "home-only/darwin hosts in nixosConfigurations" leaked [ ]
  );

  check-home-only-placement = guard (
    let
      homes = builtins.attrNames flake.homeConfigurations;
      missing = builtins.filter (n: !(builtins.elem "krit@${n}" homes)) homeOnlyHostNames;
      inDarwin = builtins.filter (n: builtins.elem n (builtins.attrNames flake.darwinConfigurations)) homeOnlyHostNames;
    in
    expect "home-only hosts missing from homeConfigurations or leaked into darwin" (missing ++ inDarwin) [ ]
  );

  check-home-covers-nixos = guard (
    let
      homes = builtins.attrNames flake.homeConfigurations;
      missing = builtins.filter (n: !(builtins.elem "krit@${n}" homes)) (builtins.attrNames flake.nixosConfigurations);
    in
    expect "nixos hosts without krit@<host> homeConfiguration" missing [ ]
  );

  check-home-no-darwin = guard (
    let
      homes = builtins.attrNames flake.homeConfigurations;
      leaked = builtins.filter (n: builtins.elem "krit@${n}" homes) darwinHostNames;
    in
    expect "darwin hosts in homeConfigurations" leaked [ ]
  );

  check-pkgsstable-nixos-hosts = guard (
    let results = lib.mapAttrsToList (n: h: probeCheck n h) flake.nixosConfigurations;
    in lib.findFirst (r: r != "ok") "ok" results
  );

  check-pkgsstable-darwin =
    lib.findFirst (r: r != "ok") "ok" (lib.mapAttrsToList (n: h: probeCheck n h) flake.darwinConfigurations);

  check-pkgsstable-home = guard (
    let
      probeHome = n: h:
        let
          x = h.extendModules {
            modules = [
              ({ pkgsStable, ... }: { home.file."probe-version".text = toString pkgsStable.path; })
            ];
          };
        in
        expect "${n} pkgsStable version" x.config.home.file."probe-version".text stablePath;
    in
    lib.findFirst (r: r != "ok") "ok" (lib.mapAttrsToList probeHome flake.homeConfigurations)
  );

  check-root-fs-single-definition = guard (
    let
      bad = builtins.filter (n: rootDefs flake.nixosConfigurations.${n} != 1) (builtins.attrNames flake.nixosConfigurations);
    in
    expect "hosts with != 1 definition of fileSystems.\"/\"" bad [ ]
  );

  check-stable-pin-consistent =
    let
      ref = stableLock.ref or "";
      fromNix = builtins.match ".*nixpkgs-stable\\.url = \"github:nixos/nixpkgs/([^\"]+)\".*" flakeNixText;
    in
    if ref == "" then "FAIL: flake.lock root nixpkgs-stable node has no original ref"
    else if fromNix == null then "FAIL: could not find nixpkgs-stable.url in flake.nix"
    else if builtins.head fromNix != ref then "FAIL: flake.nix pin ${builtins.head fromNix} != flake.lock original ref ${ref}"
    else if !(lib.hasPrefix (lib.removePrefix "nixos-" ref) stableVersion) then "FAIL: pin ${ref} does not match nixpkgs-stable.lib.version ${stableVersion}"
    else "ok";
}
