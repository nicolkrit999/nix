{ delib, inputs, pkgs, lib, ... }:
delib.module {
  name = "programs.skwdWall";

  options = delib.singleEnableOption false;

  # x86_64-linux only (meta.platforms on every skwd-wall package/module) -
  # safe here since this whole file lives under modules/nixos/, never
  # evaluated for Darwin.
  nixos.always = { ... }: {
    imports = [ inputs.skwd-wall.nixosModules.default ];
  };

  nixos.ifEnabled = { ... }: {
    services.skwd-deck.enable = true;
  };

  home.ifEnabled = { ... }: {
    # skwd-walld owns outputs.json/monitors.json/last-applied.json at
    # runtime (hotplug memory, live wallpaper switching, Wallhaven/semantic
    # search, Wallpaper Engine scene picking) - regenerating those from Nix
    # on every activation would stomp live state. Only a one-time,
    # non-destructive merge of general settings (not per-monitor
    # assignments) is seeded here.
    home.activation.skwdWallConfigSeed = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      configDir="''${XDG_CONFIG_HOME:-$HOME/.config}/skwd-wall-v2"
      $DRY_RUN_CMD mkdir -p "$configDir"

      configFile="$configDir/config.json"
      existing="$configFile"
      [ -f "$existing" ] || existing="${pkgs.writeText "skwd-wall-empty.json" "{}"}"
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq '. + {"restoreOnStartup": true}' "$existing" > "$configFile.new"
      $DRY_RUN_CMD mv "$configFile.new" "$configFile"
    '';
  };
}
