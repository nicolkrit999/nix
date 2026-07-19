{ delib
, pkgs
, ...
}:
let
  sharedIfEnabled =
    { cfg, ... }:
    {
      assertions = [
        {
          assertion = !cfg.enable || (cfg.serverUrl != "" && cfg.cacheName != "" && cfg.publicKey != "");
          message = ''
            attic is enabled but serverUrl/cacheName/publicKey are not all set.
            This module requires a self-hosted Attic server - it carries no default
            cache to talk to. Set myconfig.attic.serverUrl, .cacheName, and
            .publicKey for this host (or disable attic.enable).
          '';
        }
      ];

      nix.settings = {
        extra-substituters = [ "${cfg.serverUrl}/${cfg.cacheName}?priority=10&connect-timeout=5" ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.attic-client ];
    };
in
delib.module {
  name = "attic";

  options = with delib; moduleOptions {
    enable = boolOption false;
    push = boolOption false;
    serverUrl = strOption "";
    cacheName = strOption "";
    publicKey = strOption "";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled = sharedIfEnabled;

  darwin.ifEnabled = sharedIfEnabled;
}
