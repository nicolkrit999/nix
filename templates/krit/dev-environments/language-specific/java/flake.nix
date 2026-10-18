{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    { ... }@inputs:

    let
      javaVersion = 25;

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
              config.allowUnfree = true;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default =
        _final: prev:
        let
          jdk = prev."jdk${toString javaVersion}";
        in
        {
          inherit jdk;
          maven = prev.maven.override { jdk_headless = jdk; };
          # JDK 25 needs Gradle 9+ (default gradle is 8.x)
          gradle = prev.gradle_9.override { java = jdk; };
          lombok = prev.lombok.override { inherit jdk; };
        };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            JAVA_HOME = "${pkgs.jdk.home}";

            # Exported as a real variable (not only in shellHook) so
            # `nix print-dev-env --json` exposes it to non-shell consumers.
            env.JAVA_TOOL_OPTIONS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";

            packages = with pkgs; [
              jdk
              gradle
              maven
              lombok

              # User Tools
              google-java-format
              gcc
              ncurses
              patchelf
              zlib
              nodejs_latest
              visualvm

              # LSP & IDE Support
              jdt-language-server
              jetbrains.idea

              # DAP / Debugging / Testing (VSCode Extensions for Neovim)
              vscode-extensions.vscjava.vscode-java-debug
              vscode-extensions.vscjava.vscode-java-test
            ];

            shellHook = ''
              # 1. Lombok agent: set via env.JAVA_TOOL_OPTIONS above

              # 2. HIDE the tools inside .direnv so Git never sees them
              #    We use .direnv/tools because .direnv is already ignored.
              mkdir -p .direnv/tools
              ln -sfn ${pkgs.jdt-language-server} ./.direnv/tools/jdtls

              # 3. Setup Debugger & Test Extensions for Neovim (nvim-java)
              #    (These are already hidden in ~/.local/share, so they are fine)
              NVIM_PACKAGES="$HOME/.local/share/nvim/nvim-java/packages"
              mkdir -p "$NVIM_PACKAGES/java-debug-adapter"
              mkdir -p "$NVIM_PACKAGES/java-test"

              # Link vscode-java-debug
              ln -sfn "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug" \
                    "$NVIM_PACKAGES/java-debug-adapter/extension"

              # Link vscode-java-test
              ln -sfn "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test" \
                    "$NVIM_PACKAGES/java-test/extension"

              echo "✅ JDTLS and DAP Extensions linked (Hidden in .direnv)"

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

              check_begin "Java" "${pkgs.stdenv.hostPlatform.system}"
              check "JDK"        "env -u JAVA_TOOL_OPTIONS java -version"
              check "Gradle"     "env -u JAVA_TOOL_OPTIONS gradle --version"
              check "Maven"      "env -u JAVA_TOOL_OPTIONS mvn --version"
              check "Lombok"     "[ -f ${pkgs.lombok}/share/java/lombok.jar ] && echo installed"
              check "GCC"        "gcc --version"
              check "Node.js"    "node --version"
              check "patchelf"   "patchelf --version"
              check "google-java-format" "env -u JAVA_TOOL_OPTIONS google-java-format --version"
              check "jdtls"      "command -v jdtls >/dev/null && echo installed"
              check_done
            '';
          };
        }
      );
    };
}
