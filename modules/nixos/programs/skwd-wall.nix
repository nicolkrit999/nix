{ delib, inputs, pkgs, ... }:
let
  jq = "${pkgs.jq}/bin/jq";
in
delib.module {
  name = "programs.skwdWall";

  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [ inputs.skwd-wall.nixosModules.default ];
  };

  nixos.ifEnabled = _: {
    assertions = [{
      assertion = pkgs.stdenv.hostPlatform.isx86_64;
      message = "programs.skwdWall: skwd-wall only ships x86_64-linux binaries";
    }];
    services.skwd-deck.enable = true;
  };

  home.ifEnabled = _: {
    # skwd-walld owns outputs.json/monitors.json/last-applied.json at runtime, so they are
    # never generated here; only restoreOnStartup is seeded, and only when it is missing.
    home.activation.skwdWallConfigSeed = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      configDir="''${XDG_CONFIG_HOME:-$HOME/.config}/skwd-wall-v2"
      configFile="$configDir/config.json"
      run mkdir -p "$configDir"

      skwdSeed=""
      if [ ! -f "$configFile" ]; then
        skwdSeed='{"restoreOnStartup": true}'
      elif ! ${jq} -e 'has("restoreOnStartup")' "$configFile" >/dev/null 2>&1; then
        skwdSeed=$(${jq} '. + {"restoreOnStartup": true}' "$configFile" 2>/dev/null) || {
          warnEcho "skwd-wall: $configFile is not a JSON object, restoreOnStartup seed skipped"
          skwdSeed=""
        }
      fi

      if [ -n "$skwdSeed" ]; then
        if [ -z "''${DRY_RUN:-}" ]; then
          printf '%s\n' "$skwdSeed" > "$configFile.new"
          mv "$configFile.new" "$configFile"
        else
          echo "skwd-wall: would seed restoreOnStartup in $configFile"
        fi
      fi
    '';
  };
}
