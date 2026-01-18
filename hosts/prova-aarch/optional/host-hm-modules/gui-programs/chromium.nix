{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    # 1. Extensions
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton pass
      { id = "dphilobhebphkdjbpfohgikllaljmgbn"; } # Simplelogin
    ];

    commandLineArgs = [ "--enable-features=UseOzonePlatform" ];
  };
}
