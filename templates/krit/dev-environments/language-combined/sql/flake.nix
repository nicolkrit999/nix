{
  description = "SQL dev environment: clients/CLIs for SQLite/Postgres/MySQL, DBeaver GUI, browsing/linting tools, and a Python stack for scripting against DBs (compatible with the beer-inventory skill)";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
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
        {
          default = pkgs.mkShellNoCC {
            venvDir = ".venv";

            postShellHook = ''
              venvVersionWarn() {
                local venvVersion
                venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"
                [[ "$venvVersion" == "${pkgs.python313.version}"* ]] && return
                cat <<EOF
                Warning: Python version mismatch: [$venvVersion (venv)] != [${pkgs.python313.version}]
                Delete '$venvDir' and reload to rebuild for version ${pkgs.python313.version}
                EOF
              }
              venvVersionWarn

              echo ""
              echo "------------------------------------------------------------------"
              echo "🗄️  SQL Dev Environment Loaded"
              echo "------------------------------------------------------------------"
              echo "GUI:      dbeaver, sqlitebrowser"
              echo "CLI:      sqlite3, litecli, psql, pgcli, mysql, usql"
              echo "Tooling:  sqlite-utils, sqlite_web, sqlfluff, sqlparse (python), csvkit, jq"
              echo "Python:   ${pkgs.python313.version} (pandas, openpyxl, requests, ipython)"
              echo "------------------------------------------------------------------"
              echo "Note: 'sqlite-web' replaces datasette here - datasette is currently"
              echo "uninstallable on this nixpkgs pin (broken 'asgi-csrf' dependency)."
              echo "Usage: sqlite_web <db>   # note underscore; opens a local http:// UI"
              echo "------------------------------------------------------------------"
            '';

            packages = with pkgs; [
              # ============================================================
              # GUI clients
              # ============================================================
              dbeaver-bin # Universal SQL GUI client - Postgres/MySQL/SQLite/etc
              sqlitebrowser # Lightweight "DB Browser for SQLite" - quick schema/data edits

              # ============================================================
              # Database engines / servers (local dev, migrations, seeding)
              # ============================================================
              sqlite # sqlite3 CLI + libsqlite3
              postgresql # psql client + server binaries (initdb, pg_ctl, ...)
              mariadb # mysql/mariadb client + server binaries

              # ============================================================
              # CLI clients (nicer than raw psql/sqlite3 - autocomplete, syntax highlight)
              # ============================================================
              litecli # SQLite CLI with autocompletion & syntax highlighting
              pgcli # Postgres CLI with autocompletion & syntax highlighting
              usql # Universal SQL CLI - one tool for many DB engines/URLs

              # ============================================================
              # Browsing, linting, data wrangling
              # ============================================================
              sqlite-web # Browse/query any SQLite db from a local web UI (datasette alternative)
              sqlite-utils # Python CLI for SQLite: import CSV/JSON, create tables, indexes...
              sqlfluff # SQL linter & auto-formatter (many dialects)
              csvkit # CSV <-> SQL helpers (csvsql, sql2csv, csvlook, ...)
              jq # JSON wrangling (e.g. output of --json queries)

              # ============================================================
              # Python (data analysis / scripting against DBs, e.g. the
              # beer-inventory skill's beer_cli.py - stdlib sqlite3 + pandas/
              # openpyxl/requests for backfills, exports, reconciliation)
              # ============================================================
              (python313.withPackages (ps: [
                ps.pip
                ps.venvShellHook
                ps.pandas
                ps.openpyxl
                ps.requests
                ps.sqlparse # SQL parsing/formatting library
                ps.ipython
                ps.black
              ]))
            ];
          };
        }
      );
    };
}
