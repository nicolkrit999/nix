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
      # Cross-shell wrapper: `ns` opens the nix channel, `ns <query>` pre-populates the query
      (writeShellScriptBin "ns" ''
        if [ -n "$1" ]; then
          exec tv nix --input "$*"
        else
          exec tv nix
        fi
      '')
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
  };
}
