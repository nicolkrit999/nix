{ delib, ... }:
delib.module {
  name = "services.tlp";
  options = delib.singleEnableOption false;

  # Mutual exclusivity with services.auto-cpufreq is enforced via an assertion in
  # auto-cpufreq.nix (fires when both are enabled, regardless of which module owns it).
  nixos.ifEnabled = { ... }: {
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
