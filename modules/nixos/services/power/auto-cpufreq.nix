{ delib, lib, inputs, ... }:
delib.module {
  name = "services.auto-cpufreq";
  options = delib.singleEnableOption false;

  # Import the flake module (always, so option exists)
  nixos.always = {
    imports = [ inputs.auto-cpufreq.nixosModules.default ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    # Mutual exclusivity: auto-cpufreq and tlp cannot coexist — they fight over the
    # same CPU governor / EPP knobs. Assert at eval time instead of silently letting
    # both lib.mkForce each other off (which previously disabled both).
    assertions = [{
      assertion = !(myconfig.services.tlp.enable or false);
      message = "services.auto-cpufreq and services.tlp are mutually exclusive — enable only one in your host config.";
    }];

    # Disable GNOME Power Profiles daemon (conflicts with auto-cpufreq per official README)
    # Trade-off: GNOME Settings > Power won't show profile switcher, but auto-cpufreq
    # handles power management dynamically which is smarter. GNOME otherwise works fine.
    services.power-profiles-daemon.enable = lib.mkForce false;

    services.thermald.enable = true; # Intel thermal daemon - prevents overheating ⚠️: Remove if using AMD CPU
    programs.auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance"; # Max speed when plugged in
          turbo = "auto"; # Let auto-cpufreq decide turbo boost based on load
          energy_performance_preference = "balance_performance"; # HWP hint: favor speed but not at max thermal cost
        };
        battery = {
          governor = "powersave"; # Favor battery life on battery
          turbo = "never"; # Keep turbo off on battery — reduces heat, fan noise, and power draw
          energy_performance_preference = "power"; # HWP hint: maximize battery life
        };
      };
    };
  };
}
