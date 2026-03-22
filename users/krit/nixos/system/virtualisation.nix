{ delib, pkgs, lib, ... }:
delib.module {
  name = "krit.system.virtualisation";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings."mtu" = 1450;
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
    };

    environment.systemPackages = with pkgs; [
      distrobox
    ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      winboat # x86_64 only
    ];
  };

  # Distrobox exports binaries to ~/.distrobox-bin
  home.ifEnabled = { ... }: {
    home.sessionPath = [ "$HOME/.distrobox-bin" ];
  };
}
