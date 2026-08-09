{ delib, ... }:
delib.module {
  name = "programs.gnome-keyring";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" "pkcs11" ];
    };
  };
}
