let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  nixosCfg = name: flake.nixosConfigurations.${name};
  darwinCfg = flake.darwinConfigurations.Krits-MacBook-Pro;
  nasCfg = flake.homeConfigurations."krit@Nicol-NAS";

  eq = what: got: want:
    if got == want then "ok"
    else "FAIL: ${what} = ${builtins.toJSON got}, expected ${builtins.toJSON want}";

  hmVersion = name: (nixosCfg name).config.home-manager.users.krit.home.stateVersion;
  homeConst = name: (nixosCfg name).config.myconfig.constants.homeStateVersion;

  literal = file:
    let m = builtins.match ".*home\\.stateVersion = \"([^\"]+)\";.*" (builtins.readFile (flakeRoot + file));
    in if m == null then null else builtins.head m;

  nixosBase = "/users/krit/nixos/shared/home/home-base.nix";
  darwinBase = "/users/krit/darwin/home/home-base.nix";

  tryHm = v:
    (builtins.tryEval (builtins.deepSeq
      (
        ((nixosCfg "nixos-desktop").extendModules {
          modules = [{ myconfig.constants.homeStateVersion = lib.mkForce v; }];
        }).config.home-manager.users.krit.home.stateVersion
      ) 1)).success;

  hostChecks = name: {
    "check-${name}-system" = eq "${name} system.stateVersion" (nixosCfg name).config.system.stateVersion "25.11";
    "check-${name}-constant" = eq "${name} constants.homeStateVersion" (homeConst name) "25.11";
    "check-${name}-hm" = eq "${name} HM home.stateVersion" (hmVersion name) "25.11";
    "check-${name}-hm-matches-constant" = eq "${name} HM vs constant" (hmVersion name) (homeConst name);
  };
in
hostChecks "nixos-desktop" // hostChecks "nixos-laptop" // {
  "check-template-system" = eq "template system.stateVersion" (nixosCfg "template-host-minimal").config.system.stateVersion "25.11";
  "check-template-hm" = eq "template HM home.stateVersion" (hmVersion "template-host-minimal") "26.05";
  "check-template-hm-matches-constant" = eq "template HM vs constant" (hmVersion "template-host-minimal") (homeConst "template-host-minimal");

  "check-darwin-system" = eq "darwin system.stateVersion" darwinCfg.config.system.stateVersion 4;
  "check-darwin-constant" = eq "darwinStateVersion" darwinCfg.config.myconfig.constants.darwinStateVersion 4;
  "check-darwin-hm" = eq "darwin HM home.stateVersion" darwinCfg.config.home-manager.users.krit.home.stateVersion "25.11";
  "check-darwin-hm-matches-constant" = eq "darwin HM vs constant" darwinCfg.config.home-manager.users.krit.home.stateVersion darwinCfg.config.myconfig.constants.homeStateVersion;

  "check-nas-hm" = eq "Nicol-NAS home.stateVersion" nasCfg.config.home.stateVersion "26.05";
  "check-nas-hm-matches-constant" = eq "Nicol-NAS HM vs constant" nasCfg.config.home.stateVersion nasCfg.config.myconfig.constants.homeStateVersion;
  "check-nas-home-base-disabled" = eq "Nicol-NAS krit.home.base.enable" nasCfg.config.myconfig.krit.home.base.enable false;

  "check-literal-nixos-home-base-parsed" =
    let v = literal nixosBase; in if v == null then "FAIL: no home.stateVersion literal found in ${nixosBase}" else "ok";
  "check-literal-darwin-home-base-parsed" =
    let v = literal darwinBase; in if v == null then "FAIL: no home.stateVersion literal found in ${darwinBase}" else "ok";
  "check-literal-nixos-home-base-desktop" = eq "nixos home-base literal vs desktop constant" (literal nixosBase) (homeConst "nixos-desktop");
  "check-literal-nixos-home-base-laptop" = eq "nixos home-base literal vs laptop constant" (literal nixosBase) (homeConst "nixos-laptop");
  "check-literal-darwin-home-base-darwin" = eq "darwin home-base literal vs darwin constant" (literal darwinBase) darwinCfg.config.myconfig.constants.homeStateVersion;

  "check-control-unset-fails" = eq "eval with homeStateVersion = null succeeds" (tryHm null) false;
  "check-control-valid-evals" = eq "eval with homeStateVersion = \"25.11\" succeeds" (tryHm "25.11") true;
  "check-control-divergent-conflicts" = eq "eval with homeStateVersion = \"99.99\" (diverges from home-base) succeeds" (tryHm "99.99") false;
}
