{ delib, lib, ... }:
delib.module {
  name = "app-resolution-test-extra";

  nixos.always = {
    imports = [{
      options.services.flatpak.packages = lib.mkOption { type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs); default = [ ]; };
    }];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "25.11";
    home-manager.users.krit = _: {
      options.programs.plasma.resetFilesExclude = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
      config = {
        home = {
          username = lib.mkForce "krit";
          homeDirectory = lib.mkForce "/home/krit";
          stateVersion = lib.trivial.release;
        };
        programs.home-manager.enable = true;
      };
    };
  };
}
