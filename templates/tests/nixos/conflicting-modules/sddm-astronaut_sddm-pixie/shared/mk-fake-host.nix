# Builds a delib.host definition from a compact sddm-conflict scenario spec.
#
# Usage in a scenario's default.nix:
#   import ../../shared/mk-fake-host.nix {
#     name = "test-conflict-both-sddm";
#     "sddm-astronaut" = true;
#     "sddm-pixie" = true;
#   }
spec:
{ delib, ... }:
delib.host {
  name = spec.name;
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    services = {
      sddm-astronaut.enable = spec."sddm-astronaut" or false;
      sddm-pixie.enable = spec."sddm-pixie" or false;
    };
  };
}
