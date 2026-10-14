{ delib, lib, inputs, ... }:
delib.module {
  name = "services.auto-cpufreq";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.auto-cpufreq.nixosModules.default ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    assertions = [{
      assertion = !(myconfig.services.tlp.enable or false);
      message = "services.auto-cpufreq and services.tlp are mutually exclusive — enable only one in your host config.";
    }];

    services.power-profiles-daemon.enable = lib.mkForce false;

    programs.auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          turbo = "auto";
          energy_performance_preference = "balance_performance"; # HWP hint: favor speed but not at max thermal cost
        };
        battery = {
          governor = "powersave";
          turbo = "auto";
          energy_performance_preference = "power"; # HWP hint: maximize battery life
        };
      };
    };
  };
}
