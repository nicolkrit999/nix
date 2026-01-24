{ pkgs, lib, vars, config, ... }:
let
  enable = builtins.elem "gaming" (vars.useCases or [ ]);
in
{
  config = lib.mkIf enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };

    hardware.graphics.enable32Bit = true;

    boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };
  };
}
