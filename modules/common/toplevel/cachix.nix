{ delib
, pkgs
, ...
}:
delib.module {
  name = "cachix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    push = boolOption false;
    name = strOption "use-constant";
    publicKey = strOption "use-constant";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      finalName = if cfg.name == "use-constant" then myconfig.constants.cachix.name else cfg.name;
      finalKey =
        if cfg.publicKey == "use-constant" then myconfig.constants.cachix.publicKey else cfg.publicKey;
    in
    {
      nix.settings = {
        substituters = [ "https://${finalName}.cachix.org?priority=20" ];
        trusted-public-keys = [ finalKey ];
      };

      environment.systemPackages = [ pkgs.cachix ];
    };

  darwin.ifEnabled =
    { cfg, myconfig, ... }:
    let
      finalName = if cfg.name == "use-constant" then myconfig.constants.cachix.name else cfg.name;
      finalKey =
        if cfg.publicKey == "use-constant" then myconfig.constants.cachix.publicKey else cfg.publicKey;
    in
    {
      nix.settings = {
        substituters = [ "https://${finalName}.cachix.org?priority=20" ];
        trusted-public-keys = [ finalKey ];
      };

      environment.systemPackages = [ pkgs.cachix ];
    };
}
