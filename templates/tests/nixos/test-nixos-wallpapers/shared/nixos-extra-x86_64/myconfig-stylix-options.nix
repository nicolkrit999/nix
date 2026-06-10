{ delib, ... }:
# Declares myconfig.stylix.{enable,targets} so modules that route stylix
# targets through nixos.ifEnabled can evaluate.
# stylix-hm.nix provides the actual stylix color config for lib.stylix.colors.*.
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };
}
