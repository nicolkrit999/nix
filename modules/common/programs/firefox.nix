{ delib, inputs, lib, moduleSystem, ... }:
let
  overlays = [ inputs.firefox-addons.overlays.default ];
in
delib.module {
  name = "programs.firefox";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    profileName = delib.strOption "default";
  };

  # Always on: the zen-browser and librewolf layers read pkgs.firefox-addons without enabling firefox.
  nixos.always.nixpkgs.overlays = overlays;
  darwin.always.nixpkgs.overlays = overlays;
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = overlays;
  };

  myconfig.ifEnabled = { cfg, ... }: {
    stylix.targets.firefox.profileNames = [ cfg.profileName ];
  };

  home.ifEnabled = { cfg, ... }: {
    programs.firefox = {
      enable = true;
      profiles.${cfg.profileName} = { };
    };
  };
}
