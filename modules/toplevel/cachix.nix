{
  delib,
  pkgs,
  config,
  lib,
  ...
}:
delib.module {
  name = "system.cachix";

  nixos.always =
    { myconfig, ... }:
    let
      # Define your local variable 'cfg' from constants
      cfg =
        myconfig.constants.cachix or {
          enable = false;
          push = false;
          name = "";
          publicKey = "";
        };

      sopsFile = ../../hosts/${config.networking.hostName}/optional/host-sops-nix/${config.networking.hostName}-secrets-sops.yaml;
    in
    {
      # 🌟 The fix: Wrap the merge logic inside 'config'
      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          nix.settings = {
            substituters = [ "https://${cfg.name}.cachix.org" ];
            trusted-public-keys = [ cfg.publicKey ];
          };
          environment.systemPackages = [ pkgs.cachix ];
        })
        (lib.mkIf (cfg.enable && cfg.push) {
          sops.secrets."cachix-auth-token" = {
            inherit sopsFile;
            mode = "0440";
            owner = myconfig.constants.username; # Ensure this matches your constants naming
            group = "wheel";
          };

          environment.shellAliases = {
            rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${
              config.sops.secrets."cachix-auth-token".path
            }) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${cfg.name}";
          };
        })
      ];
    };
}
