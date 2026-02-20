{
  description = "A Nix-flake-based C/C++ development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0"; # stable Nixpkgs

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

                    (conan.overrideAttrs (oldAttrs: {
                      doCheck = false;
                      checkPhase = "true";
                      pytestCheckPhase = "true";
                    }))

                    cppcheck
                    doxygen
                    gtest
                    jetbrains.clion # C/C++ IDE
                    lcov
                    vcpkg
                    vcpkg-tool

                    # Neovim plugins
                    (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
                      p.python
                      p.cpp
                    ]))

                  ]
                  ++ (if stdenv.hostPlatform.system == "aarch64-darwin" then [ ] else [ gdb ]);
              };
        }
      );
    };
}
