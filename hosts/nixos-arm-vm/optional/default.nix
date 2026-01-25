{ lib, ... }: {
  imports = [ ]
    # 1. General Home Manager Modules
    # Note: "modules.nix" is imported by flake.nix
    ++ lib.optional (builtins.pathExists ./general-hm-modules/default.nix)
    ./general-hm-modules

    # 2. Host Home Manager Modules (e.g. gui-programs)
    ++ lib.optional (builtins.pathExists ./host-hm-modules/default.nix)
    ./host-hm-modules

    # 3. Host Packages (e.g. flatpak, local-packages)
    ++ lib.optional (builtins.pathExists ./host-packages/default.nix)
    ./host-packages

    # 4. Host Sops Nix (Secrets)
    # I handle them with "configuration.nix" so this import is not needed but left in case it's needed in the future
    ++ lib.optional (builtins.pathExists ./host-sops-nix/default.nix)
    ./host-sops-nix

    # 5. Host System Modules (e.g. nas, backup)
    ++ lib.optional (builtins.pathExists ./host-system-modules/default.nix)
    ./host-system-modules

    # 6. Various (Misc configs)
    ++ lib.optional (builtins.pathExists ./various/default.nix) ./various;
}
