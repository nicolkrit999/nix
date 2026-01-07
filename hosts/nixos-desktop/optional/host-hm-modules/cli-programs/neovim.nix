{ pkgs, lib, ... }:
{
  programs.neovim = {

    enable = true;
    viAlias = true;
    vimAlias = true;
    package = lib.mkForce (lib.hiPrio pkgs.neovim-unwrapped);

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

      # -- Other --
      nixpkgs-fmt

      # --- Treesitter & Parsers ---
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
        p.python
        p.cpp
        p.lua
        p.vim
        p.json
        p.toml
        p.html
        p.hyprlang
        p.regex
      ]))

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

  # ☕ JAVA TOOLS BRIDGE
  # 1. Provide the JDTLS binary to your 'tools' directory for shell/nvim sync
  home.file."tools/jdtls".source = pkgs.jdt-language-server;

  # 2. Link the Java Debugger extension where nvim-java expects it
  # This resolves the "No delegateCommandHandler for resolveMainClass" error
  home.file.".local/share/nvim/nvim-java/packages/java-debug-adapter/extension".source =
    "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug";

  # 3. Link the Java Test extension where nvim-java expects it
  home.file.".local/share/nvim/nvim-java/packages/java-test/extension".source =
    "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test";
}
