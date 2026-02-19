{
  description = "A Nix-flake-based Python development environment";

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
                  cat <<EOF
                  Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
                  Delete '$venvDir' and reload to rebuild for version ${python.version}
                  EOF
                }
                venvVersionWarn
              '';

              packages = with python.pkgs; [
                python # The Python interpreter itself
                # 1. PYTHON PACKAGES & HOOKS
                black # The uncompromising code formatter
                flake8 # Style guide enforcement
                isort # Sort imports alphabetically
                pip # Package installer for Python
                pylint # Source code analyzer
                setuptools # Library for packaging Python projects
                venvShellHook # Hook to create and manage virtual-environments

                # 2. TOP-LEVEL TOOLS (static)
                pkgs.pyright # Static type checker (Written in TS, top-level pkg)
                pkgs.ruff # Extremely fast Python linter (Written in Rust, top-level pkg)
                #pkgs.jetbrains.pycharm-oss

                # 3. NEOVIM PLUGINS
                pkgs.vimPlugins.coc-pyright # Python support for CoC
                (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [ p.python ]))
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

          # Option 4: python 3.11 (older)
          py311 = mkPythonShell "311";
        }

      );
    };
}
