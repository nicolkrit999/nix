{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nicol-nas.local-packages";
  options = delib.singleEnableOption false;

  # Home-manager-only host (UGOS appliance, no NixOS) - packages go through
  # home.packages, not users.users.<user>.packages (that's the NixOS-only
  # pattern used by krit.services.desktop.local-packages).
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
      ];
    };
}
