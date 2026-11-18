{ delib
, config
, lib
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

  nixos.ifEnabled =
    { myconfig, ... }@args:
    let
      inherit (myconfig.constants) wallpapers fallbackWallpaperURL fallbackWallpaperSHA256;
      pairs = lib.concatMap
        (w: [
          { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; }
          { url = w.gifURL; sha256 = w.gifSHA256; }
          { url = w.videoURL; sha256 = w.videoSHA256; }
        ])
        wallpapers
      ++ [{ url = fallbackWallpaperURL; sha256 = fallbackWallpaperSHA256; }];
      assets = lib.unique (lib.filter (p: p.url != "") pairs);
    in
    lib.mkMerge [
      (sharedIfEnabled args)
      {
        # Every wallpaper/gif/video the config fetches, as one store path, so CI can
        # `cachix pin` it (see Documentation/usage/ci/build-workflows.md, "Wallpaper
        # asset pin"). Same fetchurl attrs as the consumers, so the store paths match.
        system.build.wallpaperAssets = pkgs.linkFarm "wallpaper-assets" (
          lib.imap0
            (i: p: {
              name = "${toString i}-${(pkgs.fetchurl p).name}";
              path = pkgs.fetchurl p;
            })
            assets
        );
      }
    ];

  darwin.ifEnabled = sharedIfEnabled;
}
