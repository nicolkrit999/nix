{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    { self, ... }@inputs:

    let
      javaVersion = 25;

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
              config.allowUnfree = true;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default =
        final: prev:
        let
          jdk = prev."jdk${toString javaVersion}";
        in
        {
          inherit jdk;
          maven = prev.maven.override { jdk_headless = jdk; };
          gradle = prev.gradle.override { java = jdk; };
          lombok = prev.lombok.override { inherit jdk; };
        };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            JAVA_HOME = "${pkgs.jdk.home}";

            packages = with pkgs; [
              jdk
              gradle
              maven
              lombok

              # User Tools
              gcc
              ncurses
              patchelf
              zlib
              nodejs

              # LSP & IDE Support
              jdt-language-server
              #jetbrains.idea-community

              # DAP / Debugging / Testing (VSCode Extensions for Neovim)
              vscode-extensions.vscjava.vscode-java-debug
              vscode-extensions.vscjava.vscode-java-test
              vimPlugins.nvim-java-test
            ];

            shellHook =
              let
                loadLombok = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
                prevOptions = "\${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}";
              in
              ''
                # 1. Lombok Setup
                export JAVA_TOOL_OPTIONS="${loadLombok}${prevOptions}"

                # 2. User Info
                echo "☕ Java Environment Active (JDK ${toString javaVersion})"

                # 3. HIDE the tools inside .direnv so Git never sees them
                #    We use .direnv/tools because .direnv is already ignored.
                mkdir -p .direnv/tools
                ln -sfn ${pkgs.jdt-language-server} ./.direnv/tools/jdtls

                # 4. Setup Debugger & Test Extensions for Neovim (nvim-java)
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
              '';
          };
        }
      );
    };
}
