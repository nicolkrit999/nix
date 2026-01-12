{ pkgs }:
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
  jetbrains.clion
  lcov
  vcpkg
  vcpkg-tool
]
++ (if stdenv.hostPlatform.system == "aarch64-darwin" then [ ] else [ gdb ])
