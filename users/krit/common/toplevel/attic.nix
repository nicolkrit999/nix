{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.attic";

  options = with delib; moduleOptions {
    enable = boolOption false;
    push = boolOption false;
    serverUrl = strOption "http://nicol-nas:8081";
    cacheName = strOption "krit-nix";
    publicKey = strOption "krit-nix:w2PBueADeXiJo5Arr0l8Sys7lVyneH+cArzufUU9tSY=";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      nix.settings = {
        extra-substituters = [ "${cfg.serverUrl}/${cfg.cacheName}" ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.attic-client ];
    };

  darwin.ifEnabled =
    { cfg, ... }:
    {
      nix.settings = {
        extra-substituters = [ "${cfg.serverUrl}/${cfg.cacheName}" ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.attic-client ];
    };
}
