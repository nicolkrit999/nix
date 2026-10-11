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

    xdg.configFile."television/config.toml".text = ''
      # Managed by home-manager - do not edit manually
      tick_rate = 50
    '';

    home.activation.updateTelevisionChannels = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      stamp="''${XDG_STATE_HOME:-$HOME/.local/state}/television-channels.stamp"
      want="${pkgs.television}"
      if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ]; then
        if $DRY_RUN_CMD ${pkgs.television}/bin/tv update-channels; then
          if [ -z "''${DRY_RUN:-}" ]; then
            mkdir -p "$(dirname "$stamp")"
            printf '%s' "$want" > "$stamp"
          fi
        else
          echo "television: tv update-channels failed; will retry next activation" >&2
        fi
      fi
    '';
  };
}
