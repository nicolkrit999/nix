{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nicol-nas.local-packages";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { ... }:
    {
      home.packages = with pkgs; [
        htop # Interactive process viewer
        btop # Resource monitor (CPU/mem/disk/net)
        ncdu # Disk usage analyzer (ncurses)
        duf # Disk usage/free utility
        dust # Intuitive disk usage (du alternative)
        ripgrep # Fast recursive grep
        fd # Fast, user-friendly find alternative
        tree # Directory tree viewer
        jq # JSON processor
        unzip # Zip archive extraction
        zip # Zip archive creation
        rsync # File sync/transfer tool
        wget # File downloader
        fastfetch # System info fetch tool
        tealdeer # tldr client (concise man pages)
        neovim # Text editor
        sops # edit/decrypt repo secrets on the NAS - makes the sops-host alias work
        age # key tooling for sops
      ];
    };
}
