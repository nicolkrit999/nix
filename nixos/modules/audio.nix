{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # -----------------------------------------------------------------------
    # ⚙️ LOW LATENCY CONFIG
    # -----------------------------------------------------------------------
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
      };
    };

    # -----------------------------------------------------------------------
    # 🔊 PULSE AUDIO COMPATIBILITY
    # -----------------------------------------------------------------------
    extraConfig.pipewire-pulse."99-no-flat-volume" = {
      "pulse.properties" = {
        "pulse.min.quantum" = "1024/48000";
        "pulse.flat-volume" = false;
      };
    };

    # -----------------------------------------------------------------------
    # 🔧 GENERIC OPTICAL/DIGITAL AUDIO FIX
    # -----------------------------------------------------------------------
    # This rule applies to ANY device with "optical", "iec958" (S/PDIF),
    # or "digital" in its name. It forces a software volume mixer.
    wireplumber.extraConfig = {
      "99-optical-fix" = {
        "monitor.alsa.rules" = [
          {
            "matches" = [
              # Match SPDIF outputs
              { "node.name" = "~.*SPDIF.*"; }
              # Match standard Optical output
              { "node.name" = "~.*optical.*"; }
              # Match standard IEC958 (internal sound cards)
              { "node.name" = "~.*iec958.*"; }
              # Match generic Digital outputs (HDMI/DisplayPort)
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

      "99-firefox-lock" = {
        "pulse.rules" = [
          {
            # Target any stream from Firefox
            "matches" = [ { "application.process.binary" = "firefox"; } ];
            "actions" = {
              "update-props" = {
                "pulse.attr.volume" = "1.0";
              };
            };
          }
        ];
      };
    };
  };
}
