{
  delib,
  pkgs,
  lib,
  ...
}: # 🌟 Removed 'config'
delib.module {
  name = "cachix";
  options.cachix = with delib; {
    enable = boolOption false;
    authTokenPath = strOption ""; # 🌟 Receiver Option
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      const = myconfig.constants.cachix;
    in
    {
      nix.settings = lib.mkIf const.enable {
        substituters = [ "https://${const.name}.cachix.org" ];
        trusted-public-keys = [ const.publicKey ];
      };

      environment.systemPackages = lib.mkIf const.enable [ pkgs.cachix ];

      environment.shellAliases = lib.mkIf (const.enable && const.push) {
        # 🌟 Read the token path directly from our option
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${cfg.authTokenPath}) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${const.name}";
      };
    };
}
