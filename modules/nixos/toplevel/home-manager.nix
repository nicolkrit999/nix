{ delib, ... }:
delib.module {
  name = "home-manager";

  nixos.always = {
    home-manager = {
      # One shared nixpkgs: HM modules see the system overlays/config; nixpkgs.* inside HM then asserts
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };
  };
}
