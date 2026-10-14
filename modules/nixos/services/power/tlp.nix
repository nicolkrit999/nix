{ delib, lib, ... }:
delib.module {
  name = "services.tlp";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.power-profiles-daemon.enable = lib.mkForce false;

    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      };
    };
  };
}
