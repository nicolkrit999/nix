{ lib, ... }:
{
  imports =
    [ ]
    # 1. Local Packages (Standard packages for this host)
    ++ lib.optional (builtins.pathExists ./local-packages.nix) ./local-packages.nix

    # 2. Flatpak Support (Only if the file exists)
    ++ lib.optional (builtins.pathExists ./flatpak.nix) ./flatpak.nix;
}
