{
  description = "A Nix-flake-based C/C++ development environment";

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
              config.allowUnfree = true; # jetbrains.clion
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default =
            pkgs.mkShell.override
              {
                # Override stdenv in order to change compiler:
                # stdenv = pkgs.clangStdenv;
              }
              {
                packages =
                  with pkgs;
                  [
                    clang-tools
                    cmake
                    codespell
                    conan
                    cppcheck
                    doxygen
                    gtest
                    jetbrains.clion # C/C++ IDE
                    lcov
                    ninja
                    vcpkg
                  ]
                  ++ (if stdenv.hostPlatform.system == "aarch64-darwin" then [ ] else [ gdb ])
                  ++ lib.optionals stdenv.hostPlatform.isLinux [ valgrind ];

                # status banner on entry
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

                  check_begin "C/C++" "${pkgs.stdenv.hostPlatform.system}"
                  check "C/C++ compiler" "cc --version"
                  check "clang-tidy"      "clang-tidy --version"
                  check "clang-format"    "clang-format --version"
                  check "clangd"          "clangd --version"
                  check "CMake"           "cmake --version"
                  check "Ninja"           "ninja --version"
                  check "Conan"           "conan --version"
                  check "vcpkg"           "vcpkg version"
                  check "Cppcheck"        "cppcheck --version"
                  check "Doxygen"         "doxygen --version"
                  check "lcov"            "lcov --version"
                  check "codespell"       "codespell --version"
                  ${pkgs.lib.optionalString (
                    pkgs.stdenv.hostPlatform.system != "aarch64-darwin"
                  ) ''check "GDB"            "gdb --version"''}
                  ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''check "Valgrind"       "valgrind --version"''}
                  check_done
                '';
              };
        }
      );
    };
}
