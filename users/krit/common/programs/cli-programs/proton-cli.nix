{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.programs.proton-cli";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    _:
    let
      version = "0.9.0";
      system = pkgs.stdenv.hostPlatform.system;

      runtimeLibs = with pkgs; [ libsecret glib ];

      linuxSrc = pkgs.fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
        hash = "sha256-T2b5hLY2EITUZWe49P1IUfQnHrn3fl0YHh7/PIozJQE=";
      };

      darwinSrc = pkgs.fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
        hash = "sha256-/jKdnSpVdT9RXIo3BGdnzfD7tKV6iUYzph//n1Npbjg=";
      };

      rawLinuxBin = pkgs.runCommandLocal "proton-drive-raw-${version}" { } ''
        install -m755 -D ${linuxSrc} $out/bin/proton-drive
      '';

      linuxPackage = pkgs.buildFHSEnv {
        name = "proton-drive";
        targetPkgs = _: runtimeLibs;
        runScript = pkgs.writeShellScript "proton-drive-run" ''
          export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          exec ${rawLinuxBin}/bin/proton-drive "$@"
        '';
      };

      darwinPackage = pkgs.stdenvNoCC.mkDerivation {
        pname = "proton-drive";
        inherit version;
        src = darwinSrc;
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          runHook preInstall
          install -m755 -D $src $out/bin/proton-drive
          wrapProgram $out/bin/proton-drive \
            --prefix DYLD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
          runHook postInstall
        '';
      };

      packages = {
        x86_64-linux = linuxPackage;
        aarch64-darwin = darwinPackage;
      };
    in
    {
      home.packages = [
        (packages.${system} or (throw "proton-cli: no Proton Drive CLI build for ${system} (supported: ${lib.concatStringsSep ", " (builtins.attrNames packages)})"))
      ];
    };
}
