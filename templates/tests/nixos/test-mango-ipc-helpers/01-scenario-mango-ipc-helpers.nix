let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hm = flake.nixosConfigurations.nixos-desktop.config.home-manager.users.krit;
  s = hm.wayland.windowManager.mango.settings;

  pick = infix: list: lib.findFirst (lib.hasInfix infix) "" list;
  drvOf = str: lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext str)));
  pathOf = str: builtins.head (builtins.match ".*(/nix/store/[^ ]*/bin/[a-z-]+).*" str);

  scratchBind = pick "/bin/mango-scratch " s.bind;
  placeLine = pick "/bin/mango-place " s.exec_once;
  pipBind = pick "/bin/mango-pip" s.bind;
in
{
  scratch-path = pathOf scratchBind;
  scratch-drv = drvOf scratchBind;
  place-path = pathOf placeLine;
  place-drv = drvOf placeLine;
  pip-path = pathOf pipBind;
  pip-drv = drvOf pipBind;
}
