{ delib
, inputs
, pkgs
, ...
}:
delib.host {
  name = "nixos-arm-vm";

  nixos = {
    system.stateVersion = "25.11";

    # Overlays to solve some pipelines issue and/or other reason to override packages
    nixpkgs.overlays = [
      (_final: prev: {
        gtksourceview5 = prev.gtksourceview5.overrideAttrs (_old: {
          doCheck = false; # Skip the check that causes QEMU step to time out
        });
      })
    ];

    environment.persistence."/persist" = {
      directories = [
      ];
      files = [
      ];
    };

    imports = [
      inputs.niri.nixosModules.niri
      inputs.disko.nixosModules.disko

      ./hardware-configuration.nix
      ./disko-config-btrfs-luks-impermanence.nix

      ../../templates/krit/specialization/default.nix
      (
        { config, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;
        }
      )
    ];

    # CI doesn't need user login - use dummy password
    users.mutableUsers = true;
    users.users.krit.initialPassword = "test";
    users.users.root.initialPassword = "test";

    hardware.graphics.enable = true;

    services.logind.settings.Login = {
      HandlePowerKey = "poweroff";
      HandlePowerKeyLongPress = "poweroff";
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    environment.systemPackages = with pkgs; [
      # Keep packages for ARM compatibility testing
      distrobox
      fd
      gnupg
      pinentry-qt
      pinentry-curses
      libvdpau-va-gl
      pay-respects
      pokemon-colorscripts
      stow
      tmate
      tree
      unzip
      wget
      zip
      zlib
    ];
  };
}
