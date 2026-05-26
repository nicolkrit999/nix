# Builds a delib.host definition from a compact power-conflict scenario spec.
#
# Usage in a scenario's default.nix:
#   import ../../shared/mk-fake-host.nix {
#     name = "test-conflict-both-power";
#     tlp = true;
#     auto-cpufreq = true;
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
      tlp.enable = spec.tlp or false;
      auto-cpufreq.enable = spec."auto-cpufreq" or false;
    };
  };
}
