{ lib, ... }:
let
  sink = path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkOption {
    type = lib.types.bool;
    default = true;
  });
in
{
  options = lib.recursiveUpdate
    (lib.foldl' lib.recursiveUpdate { } (map sink [
      [ "krit" "home" "base" ]
      [ "krit" "services" "cloud" "googleDrive" ]
      [ "krit" "services" "cloud" "onedrivePersonal" ]
      [ "krit" "services" "cloud" "pcloud" ]
      [ "krit" "services" "cloud" "protonDrive" ]
      [ "krit" "services" "nas" "desktop-borg-backup" ]
      [ "krit" "services" "nas" "laptop-borg-backup" ]
      [ "krit" "services" "nas" "opencloud-mount" ]
      [ "krit" "services" "nas" "smb" ]
      [ "krit" "services" "nas" "sshfs" ]
      [ "krit" "system" "ssh-config" ]
      [ "services" "external" "dotfiles-private" ]
    ]))
    {
      myconfig = {
        services.external.dotfiles.wallpapersLink = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        services.hypridle = {
          dimTimeout = lib.mkOption { type = lib.types.int; default = 300; };
          lockTimeout = lib.mkOption { type = lib.types.int; default = 330; };
          screenOffTimeout = lib.mkOption { type = lib.types.int; default = 360; };
        };
        krit.programs.yazi.goToExclude = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
}
