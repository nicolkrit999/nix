{ delib, lib, ... }:
delib.module {
  name = "krit.system.swiss-locale";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    let
      locale = "it_CH.UTF-8";
    in
    {
      systemd.services.display-manager.environment.LC_TIME = lib.mkDefault locale;

      i18n.extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale; # file metadata only
        LC_MEASUREMENT = locale; # Metric system (km, Celsius)
        LC_MONETARY = locale; # CHF formatting
        LC_NAME = locale; # Surname Name
        LC_NUMERIC = locale; # Swiss number separators
        LC_PAPER = locale; # A4
        LC_TELEPHONE = locale; # +41 79 123 45 67
        LC_TIME = locale; # 24-hour clock and DD.MM.YYYY
      };
    };
}
