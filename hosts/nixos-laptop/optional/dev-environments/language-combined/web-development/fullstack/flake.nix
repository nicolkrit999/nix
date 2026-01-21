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
              # --- Helper Function for Clean Checks ---
              check() {
                local name="$1"
                local cmd="$2"
                # Run command, capture stdout/stderr, get first line
                local version=$(eval "$cmd" 2>&1 | head -n 1)

                if [ -n "$version" ]; then
                   printf "%-20s \033[0;32m✅ %s\033[0m\n" "$name" "$version"
                else
                   printf "%-20s \033[0;31m❌ Not Found\033[0m\n" "$name"
                fi
              }

              echo ""
              echo "------------------------------------------------------------------"
              echo "🚀 Mega-Flake: Fullstack Environment Loaded"
              echo "------------------------------------------------------------------"
              echo "--- 📦 JavaScript / Node ---"
              check "Node.js"     "node --version"
              check "npm"         "npm --version"
              check "pnpm"        "pnpm --version"
              check "yarn"        "yarn --version"
              check "TypeScript"  "tsc --version | awk '{print \$2}'"
              check "HTML/CSS LS" "vscode-html-language-server --version"

              echo ""
              echo "--- 🐍 Python ---"
              check "Python"      "python --version | awk '{print \$2}'"
              check "Pip"         "pip --version | awk '{print \$2}'"
              check "Django"      "python -m django --version"
              check "Black"       "black --version | awk '{print \$3}'"

              echo ""
              echo "--- ☕ JVM (Java/Kotlin) ---"
              # Java outputs to stderr, so we redirect
              check "Java (JDK)"  "java -version 2>&1 | awk -F '\"' '/version/ {print \$2}'"
              check "Kotlin"      "kotlin -version | awk '{print \$3}'"
              check "Spring Boot" "spring --version"
              check "Maven"       "mvn -version | awk '{print \$3}'"
              check "Gradle"      "gradle --version | grep 'Gradle' | awk '{print \$2}'"

              echo ""
              echo "--- 🐘 PHP ---"
              check "PHP"         "php --version | head -n 1 | awk '{print \$2}'"
              check "Composer"    "composer --version | awk '{print \$3}'"

              echo ""
              echo "--- 💎 Ruby ---"
              check "Ruby"        "ruby --version | awk '{print \$2}'"

              echo ""
              echo "--- 🔷 C# / .NET ---"
              check ".NET SDK"    "dotnet --version"

              echo ""
              echo "--- 🐹 Golang ---"
              check "Go"          "go version | awk '{print \$3}'"

              echo ""
              echo "--- 🗄️ Databases ---"
              check "PostgreSQL"  "psql --version | awk '{print \$3}'"
              check "MySQL"       "mysql --version | awk '{print \$3, \$5}'"
              check "MongoDB"     "mongosh --version"
              check "SQLite"      "sqlite3 --version | awk '{print \$1}'"
              echo "------------------------------------------------------------------"
            '';
          };
        }
      );
    };
}
