{ delib, ... }:
delib.module {
  name = "home-manager";

  nixos.always = {
    home-manager = {
      # Deliberate pin, see Documentation/usage/gotchas/xdg-desktop-portal-nixos.md
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };
  };
}
