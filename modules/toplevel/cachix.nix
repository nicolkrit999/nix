{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "cachix";
  options.cachix = with delib; {
    enable = boolOption false;
    push = boolOption false; # 🌟 Moved here
    name = strOption ""; # 🌟 Moved here
    publicKey = strOption ""; # 🌟 Moved here
    authTokenPath = strOption "";
  };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      nix.settings = {
        substituters = [ "https://${cfg.name}.cachix.org" ];
        trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.cachix ];

      # 🌟 ifEnabled already guarantees enable=true, just check push
      environment.shellAliases = lib.mkIf cfg.push {
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${cfg.authTokenPath}) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${cfg.name}";
      };
    };
}
