{ delib, pkgs, lib, inputs, ... }:
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
      distrobox # Allow to use other os package manager
      distroshelf # Gui manager for distrobox
      openssl_oqs # Used to generate post-quantum certificates
    ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      let pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.hostPlatform.system; };
      in [ pkgs-unstable.winboat ]
    );
  };

  # Distrobox exports binaries to ~/.distrobox-bin
  home.ifEnabled = { ... }: {
    home.sessionPath = [ "$HOME/.distrobox-bin" ];
  };
}
