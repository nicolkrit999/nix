{
  pkgs,
  pkgs-unstable,
  lib,
  vars,
  ...
}:

{
  home.packages =
    (with pkgs; [

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      vscode # IDE
      ranger # Terminal file manager
      alacritty # Terminal emulator

      winboat # Enable to run windows programs
      kdePackages.audiotube # Client for youtube music

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      killall # Command to kill processes by name
      nix-search-cli # CLI tool to search nixpkgs from terminal
      ripgrep # Fast line-oriented search tool
      unzip # Extraction utility for .zip files (used by mason in neovim)
      wtype # Send keyboard input to X11 windows
      zip # Compression utility for .zip files (used by mason in neovim)
      zlib # Compression utility for .zip files (used by mason in neovim)
      wget # Network downloader utility
    ])

    ++ (with pkgs-unstable; [
      fresh-editor # Lightweight terminal text editor
    ]);

  # 📂 XDG OVERRIDES
  # Disable folders I don't use
  xdg.userDirs = {
    publicShare = null;
    music = null;
  };

  home.sessionVariables = {
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = vars.shell == "zsh";
    enableFishIntegration = vars.shell == "fish";
    enableBashIntegration = vars.shell == "bash";
  };

  # 5. Create/remove host-specific directories
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';
  };
}
