let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";

  hasNixos = flake.nixosConfigurations != { };

  packages = [ "@scope/pkg@1.2.3" "plain-name@4.5.6" "bare" "@scope/other" ];

  mk = pkgs: flake.nixosConfigurations.template-host-minimal.extendModules {
    modules = [{
      myconfig.programs.npm = {
        enable = true;
        packages = pkgs;
      };
    }];
  };

  hmOf = x: x.config.home-manager.users.krit;
in
if !hasNixos then { skip = true; } else {
  skip = false;
  inherit packages;
  activation = builtins.unsafeDiscardStringContext (hmOf (mk packages)).home.activation.npmGlobalPackages.data;
  emptyHasActivation = (hmOf (mk [ ])).home.activation ? npmGlobalPackages;
}
