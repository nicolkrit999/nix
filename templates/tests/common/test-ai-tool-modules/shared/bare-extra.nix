{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  home-manager.users.krit = _: {
    home = {
      username = lib.mkForce "krit";
      homeDirectory = lib.mkForce "/home/krit";
      stateVersion = lib.trivial.release;
    };
    programs.home-manager.enable = true;
  };
}
