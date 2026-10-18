{
  description = "Mega-Flake: Fullstack Environment (Node, Python, Java, Go, PHP, Ruby, C#, SQL)";

  inputs = {
    # Using Unstable to ensure access to latest JDK 25 and frameworks
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
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

              nodejs_latest # Includes 'node' and 'npm'
              corepack # Includes 'pnpm' and 'yarn'
              typescript
              prettier # JS/TS/CSS/HTML/JSON formatter
              vscode-langservers-extracted # Language servers for HTML/CSS/JSON
              typescript-language-server # TypeScript/JavaScript language server

              # ---------------------------------------------------------
              # 🐍 Python 3.13 (with Django)
              # ---------------------------------------------------------
              (python313.withPackages (ps: [
                ps.pip
                ps.django # Django Framework included directly
                ps.black # Formatter
              ]))
              ruff # Python linter / language server

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
              phpPackages.composer

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
              gopls # Go language server

              # ---------------------------------------------------------
              # 🗄️ Databases (Clients & Tools)
              # ---------------------------------------------------------
              postgresql # psql client
              mysql84 # mysql client
              mongosh # MongoDB Shell client (modern replacement for mongo)
              sqlite # SQLite3
            ];

            # Entry banner: tool versions + overall verdict (never aborts the shell)
            shellHook = ''
                            # --- dev-env status banner (self-contained; removes itself in check_done) ---
              check_begin() { # check_begin <env name> <system>
                __de_ok=0 __de_total=0 __de_missing="" __de_g="" __de_r="" __de_y="" __de_b="" __de_n=""
                if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ]; then
                  __de_g='\033[0;32m' __de_r='\033[0;31m' __de_y='\033[0;33m' __de_b='\033[1m' __de_n='\033[0m'
                fi
                __de_name="$1"
                printf '\n%b🚀 %s%b  (%s)\n' "$__de_b" "$1" "$__de_n" "$2"
                printf -- '------------------------------------------------------------\n'
              }
              check() { # check <label> "<version cmd>" ["<alternate cmd>" ...]
                local label="$1" cmd out ver rc
                shift
                __de_total=$((__de_total + 1))
                for cmd in "$@"; do
                  command -v "''${cmd%% *}" >/dev/null 2>&1 || continue
                  out=$(eval "$cmd" 2>/dev/null </dev/null); rc=$?
                  ver=$(printf '%s\n' "$out" | head -n 3 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n 1)
                  if [ -z "$out" ]; then # stdout empty: the version may be on stderr (java -version)
                    out=$(eval "$cmd" 2>&1 </dev/null)
                    ver=$(printf '%s\n' "$out" | head -n 3 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n 1)
                  fi
                  __de_ok=$((__de_ok + 1))
                  if [ -n "$ver" ]; then
                    printf "  %b✅ %-20s%b %s\n" "$__de_g" "$label" "$__de_n" "$ver"
                  elif [ "$rc" -eq 0 ]; then
                    printf "  %b✅ %-20s%b %s\n" "$__de_g" "$label" "$__de_n" "installed"
                  else
                    printf "  %b⚠️  %-20s%b %s\n" "$__de_y" "$label" "$__de_n" "installed (version unknown)"
                  fi
                  return 0
                done
                __de_missing="$__de_missing''${__de_missing:+, }$label"
                printf "  %b❌ %-20s%b %s\n" "$__de_r" "$label" "$__de_n" "not found"
                return 0
              }
              check_section() { printf '%b%s%b\n' "$__de_b" "$1" "$__de_n"; }
              check_done() {
                printf -- '------------------------------------------------------------\n'
                if [ -z "$__de_missing" ]; then
                  printf "%b✅ %s ready: %s/%s tools%b\n\n" "$__de_g" "$__de_name" "$__de_ok" "$__de_total" "$__de_n"
                else
                  printf "%b⚠️  %s incomplete (%s/%s): missing %s%b\n\n" "$__de_y" "$__de_name" "$__de_ok" "$__de_total" "$__de_missing" "$__de_n"
                fi
                unset -f check_begin check check_section check_done
                unset __de_ok __de_total __de_missing __de_name __de_g __de_r __de_y __de_b __de_n
              }

                            check_begin "Fullstack" "${pkgs.stdenv.hostPlatform.system}"
                            check_section "--- JavaScript / Node ---"
                            check "Node.js" "node --version"
                            check "npm" "npm --version"
                            check "Corepack (pnpm/yarn)" "corepack --version"
                            check "TypeScript" "tsc --version | awk '{print \$2}'"
                            check "Prettier" "prettier --version"
                            check "TS language server" "typescript-language-server --version"
                            check "HTML/CSS LS" "command -v vscode-html-language-server >/dev/null && echo installed"
                            check_section "--- Python ---"
                            check "Python" "python3 --version" "python --version"
                            check "Pip" "pip --version"
                            check "Django" "python3 -m django --version"
                            check "Black" "black --version"
                            check "Ruff" "ruff --version"
                            check_section "--- JVM ---"
                            check "Java (JDK)" "java -version 2>&1 | awk -F'\"' '/version/ {v=\$2; if (v !~ /[.]/) v=v \".0\"; print v; exit}'"
                            check "Kotlin" "kotlin -version"
                            check "Spring Boot" "spring --version"
                            check "Maven" "mvn -version"
                            check "Gradle" "gradle --version | grep -m 1 '^Gradle'"
                            check_section "--- PHP / Ruby / .NET / Go ---"
                            check "PHP" "php --version"
                            check "Composer" "composer --version"
                            check "Ruby" "ruby --version"
                            check ".NET SDK" "dotnet --version"
                            check "Go" "go version"
                            check "gopls" "gopls version"
                            check_section "--- Databases ---"
                            check "PostgreSQL" "psql --version"
                            check "MySQL" "mysql --version"
                            check "MongoDB" "mongosh --version"
                            check "SQLite" "sqlite3 --version"
                            check_done
            '';
          };
        }
      );
    };
}
