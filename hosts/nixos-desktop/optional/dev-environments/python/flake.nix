{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

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
          # The function take a string such as "313" and returns the corresponding python package
          mkPythonShell =
            versionRaw:
            let
              selectedPython = pkgs."python${versionRaw}";
            in
            pkgs.mkShellNoCC {
              venvDir = ".venv";

              postShellHook = ''
                venvVersionWarn() {
                  local venvVersion
                  venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"
                  # Simple check: does the venv version start with the python version we requested?
                  [[ "$venvVersion" == "${python.version}"* ]] && return
                  cat <<EOF
                  Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
                  Delete '$venvDir' and reload to rebuild for version ${python.version}
                  EOF
                }
                venvVersionWarn
              '';

              packages = import ./packages.nix {
                inherit pkgs;
                python = selectedPython;
              };
            };
        in
        {
          # Option 1: latest
          default = mkPythonShell "315";

          # Option 2: latest stable
          py-stable = mkPythonShell "313";

          # Option 3: python 3.12 (LTS)
          py-lts = mkPythonShell "312";

          # Option 4: python 3.11 (older)
          py311 = mkPythonShell "311";
        }
      );
    };
}
