{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "common-configuration";

  darwin.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) hostname user darwinStateVersion;
      inherit (myconfig.constants.theme) polarity;
    in
    {
      system = {
        defaults = {
          dock.autohide = true;
          finder.AppleShowAllExtensions = true;
          # null leaves the key unset; it does not switch an existing Mac back to light
          NSGlobalDomain.AppleInterfaceStyle = if polarity == "dark" then "Dark" else null;
        };
        primaryUser = user;
        stateVersion = darwinStateVersion;
      };

      nixpkgs.config.allowUnfree = true;

      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      networking = {
        hostName = hostname;
        computerName = hostname;
      };

      home-manager = {
        useGlobalPkgs = true;
        backupFileExtension = "hm-backup";
      };

      environment.systemPackages = with pkgs; [
        age
        nixfmt
        nix-prefetch-scripts
        nodenv
        sops
      ];

      environment.systemPath = lib.optional config.homebrew.enable "${config.homebrew.prefix}/bin";

      programs = {
        zsh.enable = true;
        fish.enable = true;
      };
    };
}
