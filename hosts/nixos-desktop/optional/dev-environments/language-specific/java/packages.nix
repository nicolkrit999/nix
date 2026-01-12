{
  pkgs,
  jdk ? pkgs.jdk25,
}:
[
  jdk
  pkgs.gradle # Build tool
  pkgs.maven # Build tool
  pkgs.jdt-language-server # Java LSP server
  pkgs.jetbrains.idea-oss # Java IDE
]
