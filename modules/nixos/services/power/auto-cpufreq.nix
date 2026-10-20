{ delib, lib, inputs, ... }:
delib.module {
  name = "services.auto-cpufreq";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [
      (import "${inputs.auto-cpufreq}/nix/module.nix" {
        self.packages = lib.mapAttrs
          (_: p: {
            default = p.default.overridePythonAttrs (old: {
              pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "urwid" ];
            });
          })
          inputs.auto-cpufreq.packages;
      })
    ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    assertions = [{
      assertion = !(myconfig.services.tlp.enable or false);
      message = "services.auto-cpufreq and services.tlp are mutually exclusive - enable only one in your host config.";
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
