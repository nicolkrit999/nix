{ delib, ... }:
delib.module {
  name = "krit.system.virtualisation";
  options.krit.system.virtualisation = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings."mtu" = 1450;
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
    };
  };
}
