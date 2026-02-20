{ delib, pkgs, ... }:
delib.module {
  name = "krit.programs.chromium";
  options.krit.programs.chromium = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      programs.chromium = {
        enable = true;
        package = pkgs.chromium;

        # 1. Extensions
        extensions = [
          { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton pass
          { id = "dphilobhebphkdjbpfohgikllaljmgbn"; } # Simplelogin
          { id = "cdglnehniifkbagbbombnjghhcihifij"; } # Kagi Search
          { id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; } # Kagi Summarizer
          { id = "icpgjfneehieebagbmdbhnlpiopdcmna"; } # New Tab Redirect (Custom URL)
        ];

        commandLineArgs = [ "--enable-features=UseOzonePlatform" ];
      };
    };
}
