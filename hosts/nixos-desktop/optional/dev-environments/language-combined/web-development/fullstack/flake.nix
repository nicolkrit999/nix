{
  description = "Mega-Flake: Fullstack Environment (Node, Python, Java, Go, PHP, Ruby, C#, SQL)";

  inputs = {
    # Using Unstable to ensure access to latest JDK 23 and frameworks
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {

            packages = with pkgs; [

              nodejs_22 # Includes 'node' and 'npm'
              corepack # Includes 'pnpm' and 'yarn'
              typescript
              vscode-langservers-extracted # Language servers for HTML/CSS/JSON

              # ---------------------------------------------------------
              # 🐍 Python 3.13 (with Django)
              # ---------------------------------------------------------
              (python313.withPackages (ps: [
                ps.pip
                ps.venvShellHook
                ps.django # Django Framework included directly
                ps.black # Formatter
              ]))

              # ---------------------------------------------------------
              # ☕ Java 25 / Kotlin / Spring Boot
              # ---------------------------------------------------------
              jdk25 # Java 25
              kotlin
              spring-boot-cli # Spring Boot CLI
              maven # Build tool
              gradle # Build tool

              # ---------------------------------------------------------
              # 🐘 PHP
              # ---------------------------------------------------------
              php
              php83Packages.composer

              # ---------------------------------------------------------
              # 💎 Ruby
              # ---------------------------------------------------------
              ruby

              # ---------------------------------------------------------
              # 🔷 C# / .NET
              # ---------------------------------------------------------
              dotnet-sdk # The .NET SDK (C#)

              # ---------------------------------------------------------
              # 🐹 Golang
              # ---------------------------------------------------------
              go

              # ---------------------------------------------------------
              # 🗄️ Databases (Clients & Tools)
              # ---------------------------------------------------------
              postgresql # psql client
              mysql80 # mysql client
              mongosh # MongoDB Shell client (modern replacement for mongo)
              sqlite # SQLite3
            ];

            shellHook = ''
              echo "------------------------------------------------------------------"
              echo "🚀 Mega-Stack Environment Loaded!"
              echo "------------------------------------------------------------------"
              echo "Node:   $(node --version)  |  npm: $(npm --version)"
              echo "Python: $(python --version)"
              echo "Java:   $(java -version 2>&1 | head -n 1)"
              echo "Go:     $(go version | awk '{print $3}')"
              echo "PHP:    $(php --version | head -n 1 | awk '{print $2}')"
              echo "Ruby:   $(ruby --version | awk '{print $2}')"
              echo "C#:     $(dotnet --version)"
              echo "------------------------------------------------------------------"
            '';
          };
        }
      );
    };
}
