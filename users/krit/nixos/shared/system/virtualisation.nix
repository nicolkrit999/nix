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
      boxbuddy # Unofficial GUI for managing your Distroboxes
      openssl_oqs # Used to generate post-quantum certificates
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [ winboat ];
  };

  # Nothing exports here automatically; the dir is for manual `distrobox-export --export-path`
  home.ifEnabled = { ... }: {
    home.sessionPath = [ "$HOME/.distrobox-bin" ];

    home.activation.createDistroboxBin = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.distrobox-bin" || true
    '';
  };
}
