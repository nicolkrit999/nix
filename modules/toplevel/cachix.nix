{
  delib,
  pkgs,
  config,
  lib,
  ...
}:
delib.module {
  name = "system.cachix";

  myconfig.always =
    { myconfig, ... }:
    let
      # Use exactly what is defined in constants.nix
      cfg = myconfig.constants.cachix;
      user = myconfig.constants.username;

      sopsFile = ../../hosts/${config.networking.hostName}/optional/host-sops-nix/${config.networking.hostName}-secrets-sops.yaml;
    in
    {
      # Use standard NixOS syntax inside the return set
      nix.settings = lib.mkIf cfg.enable {
        substituters = [ "https://${cfg.name}.cachix.org" ];
        trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = lib.mkIf cfg.enable [ pkgs.cachix ];

      sops.secrets."cachix-auth-token" = lib.mkIf (cfg.enable && cfg.push) {
        inherit sopsFile;
        mode = "0440";
        owner = user;
        group = "wheel";
      };

      environment.shellAliases = lib.mkIf (cfg.enable && cfg.push) {
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${
          config.sops.secrets."cachix-auth-token".path
        }) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${cfg.name}";
      };
    };
}
