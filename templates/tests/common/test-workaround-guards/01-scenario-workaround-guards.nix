let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";

  hasNixos = flake.nixosConfigurations != { };
  fx = import ../../lib/fixture-host.nix flake;
  sys = "x86_64-linux";
  inherit (flake.inputs.nixpkgs) lib;

  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  vicHost = fx.mkNixos [{ myconfig.programs.vicinae.enable = lib.mkForce true; }];
  tgtHost = fx.mkNixos [{ myconfig.programs.tgt.enable = lib.mkForce true; }];
  inherit (vicHost) pkgs;
  vicRaw = flake.inputs.vicinae.packages.${sys}.default;
  vicHm = (fx.hmOf vicHost).programs.vicinae.package;
  vicSys = vicHost.config.programs.vicinae.input-server.package;
  ccv = p: p.stdenv.cc.version;

  tgtPinnedTdlib = "1.8.61";
  tgtPinnedTdlibRs = "1.4.0";
  tgtPackage = (fx.mkNixos [ ]).config.myconfig.programs.tgt.package;
  tgtPkgs = builtins.filter (p: (p.pname or "") == "tgt") tgtHost.config.environment.systemPackages;
  tgtTdlibs = builtins.filter (p: (p.pname or "") == "tdlib") tgtPackage.buildInputs;
  tgtLock = builtins.fromTOML (builtins.readFile "${flake.inputs.tgt}/Cargo.lock");
  tgtTdlibRs = map (p: p.version) (builtins.filter (p: p.name == "tdlib-rs") tgtLock.package);
in
{
  check-vicinae-hm-stdenv-follows-system = guard (
    expect "vicinae HM package cc version" (ccv vicHm) pkgs.stdenv.cc.version);

  check-vicinae-input-server-stdenv-follows-system = guard (
    expect "vicinae input-server package cc version" (ccv vicSys) pkgs.stdenv.cc.version);

  check-vicinae-hm-and-input-server-same-package = guard (
    expect "vicinae HM vs input-server drvPath" vicHm.drvPath vicSys.drvPath
  );

  warn-vicinae-override-still-needed = guard (
    if ccv vicRaw != pkgs.stdenv.cc.version then "ok"
    else "WARN: vicinae's own gcc15Stdenv now equals our stdenv cc (${ccv vicRaw}); the override is removable (memory: vicinae-gcc15stdenv-override)"
  );

  check-tgt-single-package = guard (
    expect "tgt package count (minimal fixture, only tgt enabled)" (builtins.length tgtPkgs) 1);

  check-tgt-absent-when-disabled = guard (
    expect "tgt package count (minimal fixture, tgt disabled)"
      (builtins.length (builtins.filter (p: (p.pname or "") == "tgt") (fx.mkNixos [ ]).config.environment.systemPackages)) 0);

  check-tgt-links-pinned-tdlib = guard (
    expect "tgt tdlib buildInputs versions (tgt not enabled)" (map (p: p.version) tgtTdlibs) [ tgtPinnedTdlib ]);

  check-tgt-package-option-is-installed-package = guard (
    expect "installed tgt drvPath vs myconfig.programs.tgt.package" (map (p: p.drvPath) tgtPkgs) [ tgtPackage.drvPath ]);

  check-tgt-tdlib-rs-unchanged = guard (
    if tgtTdlibRs == [ tgtPinnedTdlibRs ] then "ok"
    else "FAIL: locked tgt source now uses tdlib-rs ${builtins.toJSON tgtTdlibRs} (pin was derived for ${tgtPinnedTdlibRs}); re-derive the TDLib pin in tgt.nix from that tdlib-rs build.rs TDLIB_VERSION (memory: project-tgt-tdlib-pin)"
  );

  warn-tgt-tdlib-pin-still-needed = guard (
    if pkgs.tdlib.version != tgtPinnedTdlib then "ok"
    else "WARN: nixpkgs tdlib is ${pkgs.tdlib.version}, the version tdlib-rs needs; the TDLib pin in tgt.nix is removable (memory: project-tgt-tdlib-pin)"
  );
}
