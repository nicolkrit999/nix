{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    { self, ... }@inputs:
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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          mkJavaShell =
            jdkPackage:
            pkgs.mkShellNoCC {
              # Set JAVA_HOME so jdtls and Gradle know where to look
              JAVA_HOME = "${jdkPackage.home}";

              packages = [
                jdkPackage # The JDK itself (25 or 21)
                pkgs.gradle # Build tool
                pkgs.maven # Build tool
                pkgs.jdt-language-server # Java LSP server
                pkgs.jetbrains.idea-oss # Java IDE
              ];

              shellHook = ''
                echo "☕ Java Environment Active"
                echo "JDK: $(${jdkPackage}/bin/java -version 2>&1 | head -n 1)"
                echo "LSP: $(jdtls --version 2>/dev/null || echo 'jdtls is ready')"
              '';
            };
        in
        {
          # Option 1: JDK 25 (Latest)
          # Note: If jdk25 is not found, Nix usually aliases 'jdk' to the latest stable.
          default = mkJavaShell pkgs.jdk25;

          # Option 2: JDK 21 (LTS)
          jdk-lts = mkJavaShell pkgs.jdk21;

          # Option 3: JDK 17 (older)
          jdk17 = mkJavaShell pkgs.jdk17;
        }
      );
    };
}
