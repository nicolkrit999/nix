let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  base = flake.nixosConfigurations.${builtins.getEnv "HOST"};
  lib = flake.inputs.nixpkgs.lib;
  spec = builtins.getEnv "SPEC";
  c = if spec == "base" then base.config else base.config.specialisation.${spec}.configuration;
  sp = c.system.path;
  heavy = [
    { name = "openlogi"; enabled = c.myconfig.programs.openlogi.enable; }
  ];
  heavyNames = map (h: h.name) heavy;
  isHeavy = p: lib.elem (lib.getName p) heavyNames;
  kept = lib.filter (p: !(isHeavy p)) sp.paths;
  dropped = lib.filter isHeavy sp.paths;
  droppedNames = map lib.getName dropped;
  missing = lib.filter (h: h.enabled && !(lib.elem h.name droppedNames)) heavy;
  stray = lib.filter (h: !h.enabled && lib.elem h.name droppedNames) heavy;
in
assert lib.assertMsg (sp ? override)
  "system.path is no longer an overridable buildEnv; drop the heavy filter in 04-systempath.nix";
assert lib.assertMsg (missing == [ ])
  "enabled but not found in system.path (stale name in 04-systempath.nix): ${toString (map (h: h.name) missing)}";
assert lib.assertMsg (stray == [ ])
  "dropped although not enabled (enable predicate wrong in 04-systempath.nix): ${toString (map (h: h.name) stray)}";
assert lib.assertMsg (kept != [ ]) "heavy filter dropped every system.path entry";
(sp.override { paths = kept; }).overrideAttrs (_: {
  passthru.droppedNames = droppedNames;
})
