{ delib, pkgs, ... }:
delib.module {
  name = "services.audio";
  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      # Low Latency Config
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
        };
      };

      # Pulse Audio Compatibility
      extraConfig.pipewire-pulse."99-no-flat-volume" = {
        "pulse.properties" = {
          "pulse.min.quantum" = "1024/48000";
          "pulse.flat-volume" = false;
        };
      };

      # Stabilizes Optical/Digital Audio
      wireplumber.extraConfig = {
        "99-optical-fix" = {
          "monitor.alsa.rules" = [
            {
              "matches" = [
                { "node.name" = "~.*SPDIF.*"; }
                { "node.name" = "~.*optical.*"; }
                { "node.name" = "~.*iec958.*"; }
                { "node.name" = "~.*digital-stereo.*"; }
              ];
              "actions" = {
                "update-props" = {
                  "api.alsa.soft-mixer" = true;
                  "api.alsa.ignore-dB" = true;
                };
              };
            }
          ];
        };
      };
    };
    environment.systemPackages = with pkgs; [
      pipewire
      wireplumber
      wiremix
    ];
  };
}
