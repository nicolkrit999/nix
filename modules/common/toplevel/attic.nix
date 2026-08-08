{ delib
, config
, lib
, pkgs
, ...
}:
let
  netrcHostFor = serverUrl:
    let
      withoutScheme = lib.removePrefix "https://" (lib.removePrefix "http://" serverUrl);
      authority = lib.head (lib.splitString "/" withoutScheme);
    in
    lib.head (lib.splitString ":" authority);

  sharedIfEnabled =
    { cfg, ... }:
    let
      tokenSecretName = builtins.baseNameOf cfg.authTokenPath;
      hasAuthToken = cfg.authTokenPath != "";
    in
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
        {
          assertion = !cfg.enable || !hasAuthToken || (config.sops.secrets ? ${tokenSecretName});
          message = ''
            attic.authTokenPath is set to "${cfg.authTokenPath}" but no
            sops.secrets."${tokenSecretName}" is declared, so pull auth (via
            nix.settings.netrc-file) has nothing to render its token from.
          '';
        }
      ];

      nix.settings = {
        extra-substituters = [ "${cfg.serverUrl}/${cfg.cacheName}?priority=10&connect-timeout=5" ];
        extra-trusted-public-keys = [ cfg.publicKey ];
      } // lib.optionalAttrs hasAuthToken {
        netrc-file = config.sops.templates."attic-netrc".path;
      };

      sops.templates = lib.mkIf hasAuthToken {
        "attic-netrc".content = ''
          machine ${netrcHostFor cfg.serverUrl} password ${config.sops.placeholder.${tokenSecretName}}
        '';
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
