{ delib
, pkgs
, ...
}:
let
  sharedIfEnabled =
    { cfg, ... }:
    {
      nix.settings = {
        extra-substituters = [ "${cfg.serverUrl}/${cfg.cacheName}?priority=10&connect-timeout=5" ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.attic-client ];
    };
in
delib.module {
  name = "krit.attic";

  options = with delib; moduleOptions {
    enable = boolOption false;
    push = boolOption false;
    serverUrl = strOption "http://nicol-nas.tail9b9ae8.ts.net:8081";
    cacheName = strOption "krit-nix";
    publicKey = strOption "krit-nix:whY2oqegMU3c1dowH39O7Z7I3aAfwMpB/WZNy0/wykk=";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled = sharedIfEnabled;

  darwin.ifEnabled = sharedIfEnabled;
}
