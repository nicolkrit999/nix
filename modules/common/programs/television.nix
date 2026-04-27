{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.television";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = [ pkgs.television ];

    # Manage config.toml to prevent tv update-channels from creating one with interfering defaults
    xdg.configFile."television/config.toml".text = ''
      # Managed by home-manager - do not edit manually
      tick_rate = 50
    '';

    home.activation.updateTelevisionChannels = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.television}/bin/tv update-channels 2>/dev/null || true
    '';
  };
}
