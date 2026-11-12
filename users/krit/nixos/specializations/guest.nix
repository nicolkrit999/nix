{ delib
, lib
, config
, options
, ...
}:
let
  kritOff = lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" "krit" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" "krit" ] ++ path) options) [
        [ "programs" "claude-code-wrappers" ]
        [ "services" "cloud" "googleDrive" ]
        [ "services" "cloud" "onedrivePersonal" ]
        [ "services" "cloud" "pcloud" ]
        [ "services" "cloud" "protonDrive" ]
        [ "services" "nas" "desktop-borg-backup" ]
        [ "services" "nas" "laptop-borg-backup" ]
        [ "services" "nas" "opencloud-mount" ]
        [ "services" "nas" "smb" ]
        [ "services" "nas" "sshfs" ]
        [ "services" "desktop" "flatpak" ]
        [ "services" "laptop" "flatpak" ]
        [ "services" "windows-mount" ]
      ]
    )
  );
in
delib.module {
  name = "krit.specializations.guest";

  nixos.always = lib.mkIf config.myconfig.specializations.guest.enable {
    specialisation.guest.configuration.imports = [ kritOff ];
  };
}
