{ delib, ... }:
delib.module {
  name = "krit.programs.chromium";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.chromium = {
      enable = true;

      extensions = [
        { id = "cdglnehniifkbagbbombnjghhcihifij"; } # Kagi Search
        { id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; } # Kagi Summarizer
        { id = "dphilobhebphkdjbpfohgikllaljmgbn"; } # Simplelogin
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton pass
        { id = "icpgjfneehieebagbmdbhnlpiopdcmna"; } # New Tab Redirect (Custom URL)
      ];

      commandLineArgs = [ "--password-store=gnome-libsecret" ];
    };
  };
}
