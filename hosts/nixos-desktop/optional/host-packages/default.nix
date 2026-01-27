{ lib, ... }:
{
  imports =
    [ ]
    # 1. Local Packages
    ++ lib.optional (builtins.pathExists ./local-packages.nix) ./local-packages.nix

    # 2. Flatpak Support
    ++ lib.optional (builtins.pathExists ./flatpak.nix) ./flatpak.nix

    # 3. Custom Packages
    ++ lib.optional (builtins.pathExists ./custom-packages/default.nix) ./custom-packages/default.nix;
}
