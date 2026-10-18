{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          # 1. We define a reusable function that takes a version string (e.g., "311")
          mkPythonShell =
            versionRaw:
            let
              python = pkgs."python${versionRaw}";
            in
            pkgs.mkShellNoCC {
              venvDir = ".venv";

              # Your original hook logic, adapted to use the specific python version
              postShellHook = ''
                venvVersionWarn() {
                  local venvVersion
                  venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"
                  # Simple check: does the venv version start with the python version we requested?
                  [[ "$venvVersion" == "${python.version}"* ]] && return
                  echo "Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]"
                  echo "Delete '$venvDir' and reload to rebuild for version ${python.version}"
                }
                venvVersionWarn

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

                check_begin "Python" "${pkgs.stdenv.hostPlatform.system}"
                check "Python" "python --version"
                check "pip" "pip --version"
                check "pytest" "pytest --version"
                check "Pyright" "pyright --version"
                check "Ruff" "ruff --version"
                check_done
              '';

              packages = with python.pkgs; [
                python # The Python interpreter itself
                # 1. PYTHON PACKAGES & HOOKS
                pip # Package installer for Python
                matplotlib # Plotting library
                pytest # Test framework
                setuptools # Library for packaging Python projects
                numpy # Fundamental package for scientific computing
                venvShellHook # Hook to create and manage virtual-environments

                # 2. TOP-LEVEL TOOLS (static)
                pkgs.pyright # Static type checker (Written in TS, top-level pkg)
                pkgs.ruff # Linter, formatter and import sorter in one
                #pkgs.jetbrains.pycharm-oss
              ];
            };
        in
        {
          # Option 1: latest
          default = mkPythonShell "315";

          # Option 2: latest stable
          py-stable = mkPythonShell "313";

          # Option 3: python 3.12 (LTS)
          py-lts = mkPythonShell "312";
        }

      );
    };
}
