{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nicol-nas.local-packages";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    _:
    {
      home.packages = with pkgs; [
        # Disk and system monitoring
        btop
        duf
        dust
        htop
        ncdu
        fastfetch
        # Search and files
        fd
        jq
        ripgrep
        tree
        unzip
        zip
        # Transfer and network
        iperf3
        rsync
        wget
        # Editing and docs
        neovim
        tealdeer
        # Secrets tooling (makes the sops-host alias work on the NAS)
        age
        sops
      ];
    };
}
