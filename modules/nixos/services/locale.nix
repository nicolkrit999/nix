{ delib, lib, ... }:
let
  # Every value also lands in i18n.supportedLocales as "<value>/UTF-8"; see the spelling trap in `time`.
  localeOption =
    description:
    lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      inherit description;
    };
in
delib.module {
  name = "services.locale";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;

      address = localeOption "LC_ADDRESS: postal address layout.";
      identification = localeOption "LC_IDENTIFICATION: locale file metadata only, no visible effect.";
      measurement = localeOption "LC_MEASUREMENT: metric or imperial units.";
      monetary = localeOption "LC_MONETARY: currency symbol and money formatting.";
      name = localeOption "LC_NAME: personal name layout.";
      numeric = localeOption "LC_NUMERIC: decimal point and thousands separator.";
      paper = localeOption "LC_PAPER: default paper size.";
      telephone = localeOption "LC_TELEPHONE: telephone number format.";
      time = localeOption ''
        LC_TIME: 12/24-hour clock, date order, day and month names and first
        weekday. One locale carries all of them, they cannot be split.
        Also exported (mkDefault) to the display-manager service. The
        sddm-astronaut, sddm-pixie and hyprlock clocks ignore LC_TIME and have
        their own `use24HourClock` option.

        Spelling trap: NixOS builds i18n.supportedLocales as "<value>/UTF-8",
        but glibc lists UTF-8-only locales as `en_IN/UTF-8`. For those the
        value must be the bare name ("en_IN", not "en_IN.UTF-8"), otherwise
        the glibc-locales build fails with "unsupported locales detected"
        (nixpkgs#256688). Locales with a legacy charset in the name
        (it_CH.UTF-8, en_US.UTF-8) keep the .UTF-8 form.
      '';
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      systemd.services.display-manager.environment.LC_TIME = lib.mkDefault cfg.time;

      i18n.extraLocaleSettings = {
        LC_ADDRESS = cfg.address;
        LC_IDENTIFICATION = cfg.identification;
        LC_MEASUREMENT = cfg.measurement;
        LC_MONETARY = cfg.monetary;
        LC_NAME = cfg.name;
        LC_NUMERIC = cfg.numeric;
        LC_PAPER = cfg.paper;
        LC_TELEPHONE = cfg.telephone;
        LC_TIME = cfg.time;
      };
    };
}
