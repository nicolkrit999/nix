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
              JAVA_HOME = "${jdkPackage.home}";

              packages = import ./packages.nix {
                inherit pkgs;
                jdk = jdkPackage;
              };
              shellHook = ''
                echo "☕ Java Environment Active"

                # Check Java Version (Safe)
                echo "JDK: $(${jdkPackage}/bin/java -version 2>&1 | head -n 1)"

                # Check JDTLS location instead of running it (Prevents hanging)
                if command -v jdtls > /dev/null; then
                  echo "LSP: jdtls is ready"
                else
                  echo "LSP: jdtls NOT found"
                fi
              '';
            };
        in
        {
          # Option 1: JDK 25 (Latest)
          default = mkJavaShell pkgs.jdk25;

          # Option2: latest stable
          jdk-stable = mkJavaShell pkgs.jdk23;

          # Option 2: JDK 21 (LTS)
          jdk-lts = mkJavaShell pkgs.jdk21;

          # Option 3: JDK 17 (older)
          jdk17 = mkJavaShell pkgs.jdk17;
        }
      );
    };
}
