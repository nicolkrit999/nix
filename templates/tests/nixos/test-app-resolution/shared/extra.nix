{ delib, lib, ... }:
delib.module {
  name = "app-resolution-test-extra";

  nixos.always = {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "25.11";
    home-manager.users.krit = _: {
      home = {
        username = lib.mkForce "krit";
        homeDirectory = lib.mkForce "/home/krit";
        stateVersion = lib.trivial.release;
      };
      programs.home-manager.enable = true;
    };
  };
}
