{ delib
, config
, pkgs
, ...
}:
let
  sharedIfEnabled =
    { cfg, ... }:
    let
      tokenSecretName = builtins.baseNameOf cfg.authTokenPath;
    in
    {
      assertions = [
        {
          assertion = !cfg.push || cfg.authTokenPath == "" || (config.sops.secrets ? ${tokenSecretName});
          message = ''
            cachix.push is true and cachix.authTokenPath is set to "${cfg.authTokenPath}",
            but no sops.secrets."${tokenSecretName}" is declared, so the push aliases
            have no token file to read.
          '';
        }
      ];

      nix.settings = {
        substituters = [ "https://${cfg.name}.cachix.org?priority=20" ];
        trusted-public-keys = [ cfg.publicKey ];
      };

      environment.systemPackages = [ pkgs.cachix ];
    };
in
delib.module {
  name = "cachix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    push = boolOption false;
    name = strOption "krit-nixos";
    publicKey = strOption "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks=";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled = sharedIfEnabled;

  darwin.ifEnabled = sharedIfEnabled;
}
