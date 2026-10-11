let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  base = flake.nixosConfigurations.${builtins.getEnv "HOST"};
  spec = builtins.getEnv "SPEC";
  c = if spec == "base" then base.config else base.config.specialisation.${spec}.configuration;
in
base.pkgs.symlinkJoin { name = "sessions"; paths = c.services.displayManager.sessionPackages; }
