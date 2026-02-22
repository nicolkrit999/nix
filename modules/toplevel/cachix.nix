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
    push = boolOption false;
    name = strOption "use-constant"; # 🌟 Default to our trigger keyword
    publicKey = strOption "use-constant";
    authTokenPath = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      # 🌟 Dynamically fetch the constant if the user didn't override it in default.nix
      finalName = if cfg.name == "use-constant" then myconfig.constants.cachix.name else cfg.name;
      finalKey =
        if cfg.publicKey == "use-constant" then myconfig.constants.cachix.publicKey else cfg.publicKey;
    in
    {
      nix.settings = {
        substituters = [ "https://${finalName}.cachix.org" ];
        trusted-public-keys = [ finalKey ];
      };

      environment.systemPackages = [ pkgs.cachix ];

      environment.shellAliases = lib.mkIf cfg.push {
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${cfg.authTokenPath}) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${finalName}";
      };
    };
}
