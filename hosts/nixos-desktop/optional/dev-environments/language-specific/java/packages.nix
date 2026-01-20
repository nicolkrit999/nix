{
  pkgs,
  jdk ? pkgs.jdk25,
}:
[
  jdk
  pkgs.gradle # Build tool
  pkgs.maven # Build tool
  pkgs.nodejs # JavaScript runtime
  pkgs.jdt-language-server # Java LSP server
  pkgs.jetbrains.idea-oss # Java IDE

  # DAP and testing
  pkgs.vscode-extensions.vscjava.vscode-java-debug # Java debugger for Neovim DAP
  pkgs.vscode-extensions.vscjava.vscode-java-test # Java testing support for Neovim DAP

  # Neovim plugins
  pkgs.vimPlugins.nvim-java-test # Java testing support
]
