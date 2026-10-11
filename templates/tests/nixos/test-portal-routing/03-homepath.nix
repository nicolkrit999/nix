let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  base = flake.nixosConfigurations.${builtins.getEnv "HOST"};
  lib = flake.inputs.nixpkgs.lib;
  spec = builtins.getEnv "SPEC";
  c = if spec == "base" then base.config else base.config.specialisation.${spec}.configuration;
  hp = c.home-manager.users.krit.home.path;
  binOnly = p: p ? destination && lib.hasPrefix "/bin/" p.destination;
  kept = lib.filter (p: !(binOnly p)) hp.paths;
  dropped = lib.filter binOnly hp.paths;
in
assert lib.assertMsg (hp ? override)
  "home.path is no longer an overridable buildEnv; drop the bin-only filter in 03-homepath.nix";
assert lib.assertMsg (dropped != [ ] && kept != [ ])
  "bin-only filter dropped ${toString (lib.length dropped)} of ${toString (lib.length hp.paths)} paths";
(hp.override { paths = kept; }).overrideAttrs (_: {
  passthru.droppedNames = map (p: p.name or "?") dropped;
})
