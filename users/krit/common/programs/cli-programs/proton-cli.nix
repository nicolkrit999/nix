{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.programs.proton-cli";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { ... }:
    let
      version = "0.4.4";

      runtimeLibs = with pkgs; [ libsecret glib ];

      linuxSrc = pkgs.fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
        hash = "sha256-raEm89uUW8WmLZcAGU/C4RJISeNL15+31+o9kCQv/zI=";
      };

      darwinSrc = pkgs.fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
        hash = "sha256-8A56mjygDtQYpY8fQr0mC2cvHtJyI18Yz+7tVI3u5XM=";
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
    in
    {
      home.packages = [
        (if pkgs.stdenv.hostPlatform.isLinux then linuxPackage else darwinPackage)
      ];
    };
}
