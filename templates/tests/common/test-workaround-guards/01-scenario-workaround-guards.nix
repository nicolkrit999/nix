let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  desktop = flake.nixosConfigurations.nixos-desktop;
  darwinHost = flake.darwinConfigurations.Krits-MacBook-Pro;
  sys = "x86_64-linux";
  inherit (desktop) pkgs;

  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  hm = desktop.config.home-manager.users.krit;
  vicRaw = flake.inputs.vicinae.packages.${sys}.default;
  vicHm = hm.programs.vicinae.package;
  vicSys = desktop.config.programs.vicinae.input-server.package;
  ccv = p: p.stdenv.cc.version;

  school = desktop.config.specialisation.school.configuration;
  opencloud = builtins.filter (p: lib.hasInfix "opencloud-desktop" (p.name or "")) school.environment.systemPackages;
  qtArgs = (builtins.head opencloud).qtWrapperArgs or [ ];
  qmlPaths = builtins.filter (a: lib.hasPrefix "/nix/store/" a) qtArgs;
  expectedQml = [
    "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
    "${pkgs.kdePackages.qqc2-desktop-style}/lib/qt-6/qml"
    "${pkgs.kdePackages.qqc2-breeze-style}/lib/qt-6/qml"
  ];

  tgtPinnedTdlib = "1.8.61";
  tgtPinnedTdlibRs = "1.4.0";
  tgtPkgs = builtins.filter (p: (p.pname or "") == "tgt") desktop.config.environment.systemPackages;
  tgtTdlibs = builtins.filter (p: (p.pname or "") == "tdlib") (builtins.head tgtPkgs).buildInputs;
  tgtLock = builtins.fromTOML (builtins.readFile "${flake.inputs.tgt}/Cargo.lock");
  tgtTdlibRs = map (p: p.version) (builtins.filter (p: p.name == "tdlib-rs") tgtLock.package);

  lazygitName = h: h.catppuccin.sources.lazygit.name;
  darwinHm = darwinHost.config.home-manager.users.krit;
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
    expect "tgt package count (nixos-desktop)" (builtins.length tgtPkgs) 1);

  check-tgt-links-pinned-tdlib = guard (
    expect "tgt tdlib buildInputs versions" (map (p: p.version) tgtTdlibs) [ tgtPinnedTdlib ]);

  check-tgt-tdlib-rs-unchanged = guard (
    if tgtTdlibRs == [ tgtPinnedTdlibRs ] then "ok"
    else "FAIL: locked tgt source now uses tdlib-rs ${builtins.toJSON tgtTdlibRs} (pin was derived for ${tgtPinnedTdlibRs}); re-derive the TDLib pin in tgt.nix from that tdlib-rs build.rs TDLIB_VERSION (memory: project-tgt-tdlib-pin)"
  );

  warn-tgt-tdlib-pin-still-needed = guard (
    if pkgs.tdlib.version != tgtPinnedTdlib then "ok"
    else "WARN: nixpkgs tdlib is ${pkgs.tdlib.version}, the version tdlib-rs needs; the TDLib pin in tgt.nix is removable (memory: project-tgt-tdlib-pin)"
  );

  check-lazygit-migrated-source-nixos = guard (
    expect "lazygit source name (nixos-desktop)" (lazygitName hm) "catppuccin-lazygit-migrated");

  check-lazygit-migrated-source-darwin =
    expect "lazygit source name (darwin)" (lazygitName darwinHm) "catppuccin-lazygit-migrated";

  lazygit-source-drv = hm.catppuccin.sources.lazygit;

  lazygit-upstream-drv = flake.inputs.catppuccin.packages.${sys}.lazygit;

  check-school-opencloud-single = guard (
    expect "school opencloud-desktop package count" (builtins.length opencloud) 1);

  check-school-opencloud-qml-paths = guard (
    expect "school opencloud-desktop qml import paths" qmlPaths expectedQml
  );

  check-school-opencloud-qml-prefix-form = guard (
    expect "school opencloud-desktop qtWrapperArgs prefix triples"
      (builtins.filter (a: a == "NIXPKGS_QT6_QML_IMPORT_PATH") qtArgs)
      [ "NIXPKGS_QT6_QML_IMPORT_PATH" "NIXPKGS_QT6_QML_IMPORT_PATH" "NIXPKGS_QT6_QML_IMPORT_PATH" ]);
}
