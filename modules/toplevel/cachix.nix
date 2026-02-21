{
  delib,
  pkgs,
  lib,
  ...
}: # 🌟 Removed 'config'

# FIX: fix evaluation warnings
delib.module {
  name = "cachix";
  options.cachix = with delib; {
    enable = boolOption false;
    authTokenPath = strOption ""; # 🌟 Receiver Option
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      nix.settings = lib.mkIf myconfig.constants.enable {
        substituters = [ "https://${cfg.name}.cachix.org" ];
        trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = lib.mkIf myconfig.constants.enable [ pkgs.cachix ];

      environment.shellAliases = lib.mkIf (myconfig.constants.enable && myconfig.constants.push) {
        # 🌟 Read the token path directly from our option
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${cfg.authTokenPath}) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${myconfig.constants.name}";
      };
    };
}
