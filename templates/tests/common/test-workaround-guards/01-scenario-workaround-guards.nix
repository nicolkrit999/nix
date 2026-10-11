let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  desktop = flake.nixosConfigurations.nixos-desktop;
  darwinHost = flake.darwinConfigurations.Krits-MacBook-Pro;
  sys = "x86_64-linux";
  pkgs = desktop.pkgs;
  upstream = flake.inputs.nixpkgs.legacyPackages.${sys};

  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  hm = desktop.config.home-manager.users.krit;
  vicRaw = flake.inputs.vicinae.packages.${sys}.default;
  vicHm = hm.programs.vicinae.package;
  vicSys = desktop.config.programs.vicinae.input-server.package;
  ccv = p: p.stdenv.cc.version;

  withClaude = desktop.extendModules {
    modules = [{ myconfig.programs.claude-desktop.enable = true; }];
  };
  countPipewire = bi: builtins.length (builtins.filter (p: (p.pname or "") == "pipewire") bi);
  claudeBI = withClaude.pkgs.claude-desktop.buildInputs;

  school = desktop.config.specialisation.school.configuration;
  opencloud = builtins.filter (p: lib.hasInfix "opencloud-desktop" (p.name or "")) school.environment.systemPackages;
  qtArgs = (builtins.head opencloud).qtWrapperArgs or [ ];
  qmlPaths = builtins.filter (a: lib.hasPrefix "/nix/store/" a) qtArgs;
  expectedQml = [
    "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
    "${pkgs.kdePackages.qqc2-desktop-style}/lib/qt-6/qml"
    "${pkgs.kdePackages.qqc2-breeze-style}/lib/qt-6/qml"
  ];

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

  check-claude-desktop-has-pipewire = guard (
    if countPipewire claudeBI >= 1 then "ok"
    else "FAIL: claude-desktop buildInputs lack pipewire (memory: claude-desktop-pipewire-overlay)"
  );

  warn-claude-desktop-overlay-redundant = guard (
    if countPipewire claudeBI < 2 then "ok"
    else "WARN: claude-desktop upstream buildInputs already contain pipewire; overlay is removable (memory: claude-desktop-pipewire-overlay)"
  );

  check-lazygit-migrated-source-nixos = guard (
    expect "lazygit source name (nixos-desktop)" (lazygitName hm) "catppuccin-lazygit-migrated");

  check-lazygit-migrated-source-darwin =
    expect "lazygit source name (darwin)" (lazygitName darwinHm) "catppuccin-lazygit-migrated";

  lazygit-source-drv = hm.catppuccin.sources.lazygit;

  lazygit-upstream-drv = flake.inputs.catppuccin.packages.${sys}.lazygit;

  check-openblas-i686-docheck-disabled = guard (
    expect "pkgsi686Linux.openblas.doCheck" pkgs.pkgsi686Linux.openblas.doCheck false
  );

  check-openblas-x86_64-untouched = guard (
    expect "x86_64 openblas.doCheck vs plain nixpkgs" pkgs.openblas.doCheck upstream.openblas.doCheck
  );

  warn-openblas-i686-override-still-needed = guard (
    if upstream.pkgsi686Linux.openblas.doCheck != false then "ok"
    else "WARN: plain nixpkgs already has pkgsi686Linux.openblas.doCheck = false; overlay is removable (memory: openblas-i686-docheck-workaround)"
  );

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
