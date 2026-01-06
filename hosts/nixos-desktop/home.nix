{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  home.packages =
    (with pkgs; [

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      vscode # It is the default but i want to keep it in case i change the default editor later
      ranger # It is not the default but i want to keep it
      alacritty # It is not the default but i want to keep it

      #winboat # Enable to run windows programs
      kdePackages.audiotube # Client for youtube music
      # Useful command to kill processes by name, such as waybar after a crash

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      killall
      nix-search-cli # CLI tool to search nixpkgs from terminal
      ripgrep # Fast line-oriented search tool (needed by neovim) -> ⚠️ KEEP
      unzip # Extraction utility for .zip files (used by mason in neovim) -> ⚠️ KEEP
      wtype
      zip # Compression utility for .zip files (used by mason in neovim) -> ⚠️ KEEP
      zlib # Compression utility for .zip files (used by mason in neovim) -> ⚠️ KEEP
      wget

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      jdk25 # Java Development Kit (needed for some Neovim LSP servers) -> ⚠️ KEEP
      nodejs # JavaScript runtime (needed for some Neovim plugins and LSP servers) -> ⚠️ KEEP

      (pkgs.python313.withPackages (
        ps: with ps; [
          black # The uncompromising code formatter
          flake8 # Style guide enforcement
          pip # Package installer for Python
          ruff # Extremely fast Python linter
        ]
      ))
    ])
    ++ (with pkgs-unstable; [

    ]);

  # ☕ JAVA TOOLS
  # This only exists on this specific machine
  home.file."tools/jdtls".source = pkgs.jdt-language-server;

  # 📂 XDG OVERRIDES
  # Disable folders I don't use
  xdg.userDirs = {
    publicShare = null;
    music = null;
  };

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk25}";
    JDTLS_BIN = "${pkgs.jdt-language-server}/bin/jdtls";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # 5. Create/remove host-specific directories
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';
  };
}
