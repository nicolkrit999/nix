{ delib, ... }:
delib.module {
  name = "krit.system.swiss-locale";
  options.krit.system.swiss-locale = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    # Swiss locale settings for numbers, dates, and measurements
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "it_CH.UTF-8"; # Address formatting
      LC_IDENTIFICATION = "it_CH.UTF-8"; # Identification formatting for files (only metadata)
      LC_MEASUREMENT = "it_CH.UTF-8"; # Uses Metric system (km, Celsius)
      LC_MONETARY = "it_CH.UTF-8"; # Uses CHF formatting
      LC_NAME = "it_CH.UTF-8"; # Personal name formatting (Surname Name)
      LC_NUMERIC = "it_CH.UTF-8"; # Swiss number separators
      LC_PAPER = "it_CH.UTF-8"; # Defaults printers to A4
      LC_TELEPHONE = "it_CH.UTF-8"; # Telephone number formatting (e.g. +41 79 123 45 67)
      LC_TIME = "it_CH.UTF-8"; # 24-hour clock and DD.MM.YYYY
    };
  };
}
