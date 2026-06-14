{ delib, ... }:
delib.module {
  name = "programs.gnome-keyring";
  options = delib.singleEnableOption false;

  # PAM only unlocks the keyring; this runs the --start handshake that registers
  # org.freedesktop.secrets at session start (missing under UWSM/Hyprland).
  home.ifEnabled = {
    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" "pkcs11" ];
    };
  };
}
