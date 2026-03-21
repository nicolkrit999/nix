{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.television";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = with pkgs; [
      television
      nix-search-tv
    ];

    # Write the nix cable file directly to avoid fish shell errors
    xdg.configFile."television/cable/nix.toml".text = ''
      [metadata]
      name = "nix"
      requirements = ["nix-search-tv"]

      [source]
      command = "nix-search-tv print"

      [preview]
      command = "nix-search-tv preview {}"
    '';

    home.shellAliases.ns = "tv nix";
  };
}
