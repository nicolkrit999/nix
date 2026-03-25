{ delib, lib, inputs, ... }:
delib.module {
  name = "services.auto-cpufreq";
  options = delib.singleEnableOption false;

  # Import the flake module (always, so option exists)
  nixos.always = {
    imports = [ inputs.auto-cpufreq.nixosModules.default ];
  };

  nixos.ifEnabled = { ... }: {
    # Mutual exclusivity: disable TLP when auto-cpufreq is enabled
    services.tlp.enable = lib.mkForce false;
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
        };
        battery = {
          governor = "powersave"; # Favor battery life on battery
          turbo = "auto"; # Let auto-cpufreq decide turbo boost based on load
        };
      };
    };
  };
}
