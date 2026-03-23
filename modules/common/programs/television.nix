{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.television";
  options = delib.singleEnableOption false;

  # FIXME: the nix-search-tv is still not consistent. Some time it work some other it doesn't
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

    # Manage config.toml to prevent tv update-channels from creating one with interfering defaults
    xdg.configFile."television/config.toml".text = ''
      # Managed by home-manager - do not edit manually
      tick_rate = 50
    '';

    # Auto-update channels on activation so users don't need to run it manually
    home.activation.updateTelevisionChannels = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.television}/bin/tv update-channels 2>/dev/null || true
    '';
  };
}
