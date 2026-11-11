{ delib, pkgs, lib, ... }:
let
  appType = lib.types.submodule {
    options = {
      pname = lib.mkOption { type = lib.types.str; };
      version = lib.mkOption { type = lib.types.str; };
      url = lib.mkOption { type = lib.types.str; };
      hash = lib.mkOption { type = lib.types.str; };
      extraPkgs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
    };
  };

  mkApp = app: pkgs.appimageTools.wrapType2 (finalAttrs: {
    inherit (app) pname version;

    src = pkgs.fetchurl { inherit (app) url hash; };

    extraPkgs = _: app.extraPkgs;

    extraInstallCommands = ''
      desktop=$(find ${finalAttrs.contents} -maxdepth 1 -name '*.desktop' | head -n1)
      install -m 444 -D "$desktop" $out/share/applications/${app.pname}.desktop
      # Absolute store path: a bare name resolves via PATH and can hit an unrelated binary.
      sed -i -E "s|^Exec=.*|Exec=$out/bin/${app.pname} --no-sandbox %U|" $out/share/applications/${app.pname}.desktop
      if [ -d ${finalAttrs.contents}/usr/share/icons ]; then
        cp -r ${finalAttrs.contents}/usr/share/icons $out/share
      fi
    '';

    meta = {
      mainProgram = app.pname;
      platforms = [ "x86_64-linux" ];
    };
  });
in
delib.module {
  name = "programs.appimages";
  options = with delib; moduleOptions {
    enable = boolOption false;
    apps = listOfOption appType [ ];
  };

  nixos.ifEnabled = { cfg, ... }: {
    environment.systemPackages = map mkApp cfg.apps;
  };
}
