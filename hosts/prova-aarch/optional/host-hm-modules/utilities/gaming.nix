{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  hardware.graphics = {
    enable = true;
    # FIX: 32bit Not supported on aarch64
    enable32Bit = false; # Not supported on aarch64
  };
}
