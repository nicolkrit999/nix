{ delib
, pkgs
, inputs
, lib
, config
, moduleSystem
, ...
}:
delib.module {
  name = "programs.niri";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [
      inputs.niri.nixosModules.niri
    ];
    programs.niri.package = pkgs.niri;
    niri-flake.cache.enable = false;
  };

  home.always = { ... }: lib.optionalAttrs (moduleSystem == "home") {
    imports = [
      inputs.niri.homeModules.niri
    ];
    programs.niri.package = pkgs.niri;
  };

  nixos.ifEnabled = {
    programs.niri.enable = true;
    systemd.user.services.niri-flake-polkit.enable = lib.mkForce false;
    home-manager.sharedModules = lib.mkIf (!config.stylix.enable) [
      {
        key = "niri-stylix-off-enable-stub";
        options.stylix.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      }
    ];
  };
}
