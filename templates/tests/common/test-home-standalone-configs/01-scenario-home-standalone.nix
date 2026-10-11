let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  homes = flake.homeConfigurations;
  nas = homes."krit@Nicol-NAS";
  nasCfg = nas.config;

  hasNixos = flake.nixosConfigurations != { };
  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  isDrv = s: builtins.match "/nix/store/.*\\.drv" s != null;

  instantiates = name: home:
    let
      path = builtins.tryEval (builtins.unsafeDiscardStringContext home.config.home.path.drvPath);
      act = builtins.tryEval (builtins.unsafeDiscardStringContext home.activationPackage.drvPath);
    in
    if !path.success then "FAIL: ${name}: home.path.drvPath does not evaluate"
    else if !act.success then "FAIL: ${name}: activationPackage.drvPath does not evaluate"
    else if !(isDrv path.value && isDrv act.value) then "FAIL: ${name}: drvPath is not a .drv store path"
    else "ok";

  stableProbe =
    let
      x = nas.extendModules {
        modules = [
          ({ pkgsStable, ... }: {
            home.file."probe-stable-version".text = pkgsStable.lib.version;
            home.file."probe-stable-path".text = toString pkgsStable.path;
          })
        ];
      };
    in
    {
      version = x.config.home.file."probe-stable-version".text;
      path = x.config.home.file."probe-stable-path".text;
    };

in
{
  hostNames = builtins.attrNames homes;

  check-host-instantiates = hostName: instantiates hostName homes.${hostName};

  check-catppuccin-home-mode =
    expect "NAS catppuccin enable/autoEnable"
      [ nasCfg.catppuccin.enable nasCfg.catppuccin.autoEnable ]
      [ true false ];

  check-pkgsstable-source =
    expect "pkgsStable source path" stableProbe.path (toString flake.inputs.nixpkgs-stable);

  check-pkgsstable-older-than-main =
    if lib.versionOlder stableProbe.version lib.version then "ok"
    else "FAIL: pkgsStable (${stableProbe.version}) is not older than nixpkgs (${lib.version})";

  check-substituters-match-nixos = guard (
    expect "NAS vs NixOS extra-substituters"
      nasCfg.nix.settings.extra-substituters
      flake.nixosConfigurations.template-host-minimal.config.nix.settings.extra-substituters
  );

  check-trusted-keys-match-nixos = guard (
    expect "NAS vs NixOS extra-trusted-public-keys"
      nasCfg.nix.settings.extra-trusted-public-keys
      flake.nixosConfigurations.template-host-minimal.config.nix.settings.extra-trusted-public-keys
  );

  check-nix-conf-rendered =
    if nasCfg.nix.settings.extra-substituters == [ ] then "FAIL: NAS extra-substituters empty"
    else expect "nix/nix.conf xdg.configFile enabled" (nasCfg.xdg.configFile."nix/nix.conf".enable or false) true;
}
