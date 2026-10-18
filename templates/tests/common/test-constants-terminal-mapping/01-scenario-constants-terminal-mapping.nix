let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  systems = [ "x86_64-linux" "aarch64-darwin" ];
  pkgsOf = s: flake.inputs.nixpkgs.legacyPackages.${s};

  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;
  darwin = flake.darwinConfigurations.Krits-MacBook-Pro;
  termName = c: c.config.myconfig.constants.terminal.name;

  moduleDir = /. + "${flakeRoot}/users/krit/common/programs/terminal-emulators";
  stems = map (lib.removeSuffix ".nix")
    (builtins.attrNames (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir moduleDir)));

  exeName = p: p.meta.mainProgram or p.pname or null;
  resolves = s: n:
    let p = pkgsOf s; in
    p ? ${n} && lib.meta.availableOn p.stdenv.hostPlatform p.${n} && exeName p.${n} == n;

  eq = what: got: want:
    if got == want then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON want}, got ${builtins.toJSON got}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";

  nameChecks = label: n:
    lib.listToAttrs (map
      (s: lib.nameValuePair "${label} (${n}): nixpkgs attr with a /bin/${n} exe on ${s}"
        (yes "pkgs.${n} missing, unavailable on ${s} or its exe is not ${n}" (resolves s n)))
      systems);

  defaultName = desktop.options.myconfig.constants.terminal.name.default;

  moduleChecks = lib.listToAttrs (map
    (stem: lib.nameValuePair "module ${stem}: krit.programs.${stem} option exists on both platforms"
      (yes "no myconfig.krit.programs.${stem} on nixos/darwin"
        (desktop.options.myconfig.krit.programs ? ${stem} && darwin.options.myconfig.krit.programs ? ${stem})))
    stems);

  checks =
    nameChecks "constants default" defaultName
    // lib.foldl' (acc: n: acc // nameChecks "terminal module" n) { } stems
    // nameChecks "nixos-desktop" (termName desktop)
    // nameChecks "nixos-laptop" (termName laptop)
    // nameChecks "darwin host" (termName darwin)
    // moduleChecks
    // {
      "terminal modules were discovered" = yes "no terminal-emulators/*.nix found" (stems != [ ]);
      "constants default is one of the terminal modules" = yes "default ${defaultName} has no module in ${toString stems}" (builtins.elem defaultName stems);
      "control: unknown terminal name does not resolve" = eq "resolves" (resolves "x86_64-linux" "no-such-terminal-xyz") false;
      "control: nixpkgs attr whose exe differs from its name does not resolve" =
        eq "resolves" (resolves "x86_64-linux" "ripgrep") false;
    };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
