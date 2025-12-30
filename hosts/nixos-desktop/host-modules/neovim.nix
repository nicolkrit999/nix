{ pkgs, ... }:
{
  programs.neovim = {

    # Extra packages to install for Neovim's backend functionality
    extraPackages = with pkgs; [

      # -- System tools --
      gcc
      gnumake

      # --- Runtimes (Vital for Mason & Plugins) ---
      jdk25 # Java Development Kit
      nodejs # JavaScript runtime
      python313 # Python 3.13 interpreter

      # --- Language Servers (LSP) ---
      bash-language-server # Bash Language Server
      lua-language-server # Lua Language Server
      nixd # Nix language server
      jdt-language-server # Java Language Server
      python313Packages.python-lsp-server # Python Language Server
      yaml-language-server # YAML Language Server
      vim-language-server # Vimscript Language Server

      # --- Linters & Formatters ---
      pyright # Static type checker for Python

      # --- Building ---
      maven # Java build tool
      gradle # Java build tool

      # --- Treesitter & Parsers ---
      tree-sitter # Incremental parsing system (core for syntax highlighting)
      vimPlugins.nvim-treesitter # Treesitter configurations
      vimPlugins.nvim-treesitter-parsers.hyprlang # Hyprland parser for Treesitter
      vimPlugins.nvim-treesitter-parsers.regex # Regex parser for treesitter

      # --- debuggers ---
      vscode-extensions.vscjava.vscode-java-debug # Java debugger for Neovim DAP
      vscode-extensions.vscjava.vscode-java-test # Java testing support for Neovim DAP

      # --- Plugins ---
      vimPlugins.coc-pyright # Python support for CoC
      vimPlugins.nvim-java-test # Java testing support

      # --- Fonts ---
      nerd-fonts.hack # Fonts for icons
      nerd-fonts.jetbrains-mono # JetBrains Mono with icons
    ];
  };

  # This block is a helper for java-nvim. If not in use it can be removed
  home.file.".local/share/nvim/mason/packages/java-debug-adapter/extension".source =
    let
      latestDebugAdapter = pkgs.fetchzip {
        url = "https://open-vsx.org/api/vscjava/vscode-java-debug/0.58.0/file/vscjava.vscode-java-debug-0.58.0.vsix";
        extension = "zip";
        hash = "sha256-U/6/rWHMZIcvGqcECneVQdtxP1dEmoWcuDW/CtSVLTk="; # UPDATE THIS HASH AFTER FIRST RUN
        stripRoot = false;
      };
    in
    "${latestDebugAdapter}/extension";

  # Keep Test Runner as is (it updates less often)
  home.file.".local/share/nvim/mason/packages/java-test/extension".source =
    "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test";

  home.file."tools/jdtls".source = pkgs.jdt-language-server;

}
