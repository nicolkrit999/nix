{ pkgs, lib, ... }:

{
  config = lib.mkIf (pkgs.system == "x86_64-linux") {

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
