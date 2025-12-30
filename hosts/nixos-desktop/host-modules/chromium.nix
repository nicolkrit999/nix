{ pkgs, ... }:
# TODO: add more extension
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    # 1. Extensions
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton pass
      { id = "dphilobhebphkdjbpfohgikllaljmgbn"; } # Simplelogin
      { id = "mcbpblocgmgfnpjjppndjkmgjaogfceg"; } # FireShot
    ];

    # 2. Command Line Arguments (Hardware & Session)
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
  };
}
