{ delib, lib, ... }:
delib.module {
  name = "services.tlp";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { ... }: {
    # Mutual exclusivity: disable auto-cpufreq when TLP is enabled
    programs.auto-cpufreq.enable = lib.mkForce false;

    services.thermald.enable = true; # Intel thermal daemon - prevents overheating ⚠️: Remove if using AMD CPU
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance"; # Max speed when plugged in
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave"; # Favor battery life on battery
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance"; # plugged in: Bias toward speed on AC
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power"; # on battery: Balanced, leaning toward saving power

        # Battery charge thresholds (uncomment if laptop supports them):
        # START_CHARGE_THRESH_BAT0 = 40; # Start charging below 40%
        # STOP_CHARGE_THRESH_BAT0 = 80; # Stop charging at 80% (extends battery lifespan)
      };
    };
  };
}
