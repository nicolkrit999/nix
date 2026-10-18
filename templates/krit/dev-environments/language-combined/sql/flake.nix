{
  description = "SQL dev environment: clients/CLIs for SQLite/Postgres/MySQL, DBeaver GUI, browsing/linting tools, and a Python stack for scripting against DBs (compatible with the beer-inventory skill)";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true; # dbeaver-bin
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          # `nix develop`'s $PATH is a plain concatenation of each `packages` entry's
          # bin/ dir in list order - NOT a priority-resolved buildEnv merge - so
          # `lib.hiPrio` has no effect and list order alone decides which `python3`
          # wins. litecli/pgcli/sqlite-web/sqlite-utils each drag in nixpkgs' bare
          # python3, so this env MUST stay first in `packages` or plain `python3`
          # silently resolves to an interpreter without pandas & friends.
          pythonEnv = pkgs.python313.withPackages (ps: [
            ps.pip
            ps.pandas
            ps.openpyxl
            ps.requests
            ps.sqlparse # SQL parsing/formatting library
            ps.ipython
            ps.black
          ]);
        in
        {
          default = pkgs.mkShellNoCC {
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

                            check_begin "SQL" "${pkgs.stdenv.hostPlatform.system}"
                            check_section "--- Python ---"
                            check "Python" "python3 --version"
                            check "pandas" "python3 -c 'import pandas; print(pandas.__version__)'"
                            check "Black" "black --version"
                            check_section "--- Database engines / clients ---"
                            check "SQLite" "sqlite3 --version"
                            check "DuckDB" "duckdb --version"
                            check "PostgreSQL" "psql --version"
                            check "MariaDB/MySQL" "mysql --version"
                            check "litecli" "litecli --version"
                            check "pgcli" "pgcli --version"
                            check "usql" "usql --version"
                            check "pspg" "pspg --version"
                            check_section "--- Tooling ---"
                            check "sqlite-utils" "sqlite-utils --version"
                            check "sqlite_web" "sqlite_web --help | head -n 1"
                            check "sqlfluff" "sqlfluff --version"
                            check "csvkit" "csvsql --version"
                            check "dbmate" "dbmate --version"
                            check "jq" "jq --version"
                            check_done

                            echo "datasette: upstream broken, sqlite_web is used instead"
                            echo "Usage: sqlite_web <db>   # note underscore; opens a local http:// UI"
                            echo "GUI: dbeaver, sqlitebrowser (no --version, not checked)"
            '';

            packages = with pkgs; [
              # ============================================================
              # Python (data analysis / scripting against DBs, e.g. the
              # beer-inventory skill's beer_cli.py - stdlib sqlite3 + pandas/
              # openpyxl/requests for backfills, exports, reconciliation)
              #
              # MUST be first: several tools below propagate nixpkgs' bare
              # python3, and the first bin/ on $PATH wins.
              # ============================================================
              pythonEnv

              # ============================================================
              # GUI clients
              # ============================================================
              dbeaver-bin # Universal SQL GUI client - Postgres/MySQL/SQLite/etc
              sqlitebrowser # Lightweight "DB Browser for SQLite" - quick schema/data edits

              # ============================================================
              # Database engines / servers (local dev, migrations, seeding)
              # ============================================================
              sqlite # sqlite3 CLI + libsqlite3
              duckdb # Analytical embedded SQL engine (CSV/Parquet/JSON queries)
              postgresql # psql client + server binaries (initdb, pg_ctl, ...)
              mariadb # mysql/mariadb client + server binaries

              # ============================================================
              # CLI clients (nicer than raw psql/sqlite3 - autocomplete, syntax highlight)
              # ============================================================
              litecli # SQLite CLI with autocompletion & syntax highlighting
              pgcli # Postgres CLI with autocompletion & syntax highlighting
              usql # Universal SQL CLI - one tool for many DB engines/URLs
              pspg # Pager for tabular output (psql/pgcli/mysql)

              # ============================================================
              # Browsing, linting, data wrangling
              # ============================================================
              sqlite-web # Browse/query any SQLite db from a local web UI (datasette alternative)
              sqlite-utils # Python CLI for SQLite: import CSV/JSON, create tables, indexes...
              sqlfluff # SQL linter & auto-formatter (many dialects)
              csvkit # CSV <-> SQL helpers (csvsql, sql2csv, csvlook, ...)
              dbmate # Database migration tool (SQL files, many engines)
              jq # JSON wrangling (e.g. output of --json queries)
            ];
          };
        }
      );
    };
}
