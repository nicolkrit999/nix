{ delib, lib, ... }:
delib.module {
  name = "services.sddm-exclusive";

  # One assertion for every SDDM theme module: at most one may be enabled, so any pair or the triple fails the build.
  # A new theme module only has to be added to this list.
  nixos.always = { myconfig, ... }:
    let
      themes = [ "sddm-astronaut" "sddm-pixie" "sddm-qylock" ];
      enabled = lib.filter (t: myconfig.services.${t}.enable or false) themes;
    in
    {
      assertions = [{
        assertion = lib.length enabled <= 1;
        message = "The SDDM theme modules (${lib.concatMapStringsSep ", " (t: "services.${t}") themes}) are mutually exclusive - enable only one in your host config. Enabled: ${lib.concatMapStringsSep ", " (t: "services.${t}") enabled}.";
      }];
    };
}
