let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hm = flake.nixosConfigurations.nixos-desktop.config.home-manager.users.krit;
  s = hm.wayland.windowManager.mango.settings;

  bind = lib.findFirst (lib.hasInfix "/bin/mango-screenshot ") "" s.bind;
  drvOf = str: lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext str)));
  pathOf = str: builtins.head (builtins.match ".*(/nix/store/[^ ]*/bin/[a-z-]+).*" str);
in
{
  screenshot-path = pathOf bind;
  screenshot-drv = drvOf bind;
  mango-src = flake.inputs.mango.outPath;
}
