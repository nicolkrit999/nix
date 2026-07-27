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
            shellHook = ''
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
            ];
          };
        }
      );
    };
}
