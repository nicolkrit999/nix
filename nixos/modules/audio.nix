{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
      };
    };

    extraConfig.pipewire-pulse."99-no-flat-volume" = {
      "pulse.properties" = {
        "pulse.min.quantum" = "1024/48000";
        "pulse.flat-volume" = false;
      };
    };
  };
}
