# Proton Drive CLI - official Bun-compiled single-file executable
# Reference: https://proton.me/drive/download
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

      src =
        if pkgs.stdenv.isLinux
        then
          pkgs.fetchurl
            {
              url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
              hash = "sha256-raEm89uUW8WmLZcAGU/C4RJISeNL15+31+o9kCQv/zI=";
            }
        else
          pkgs.fetchurl {
            url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
            hash = "sha256-8A56mjygDtQYpY8fQr0mC2cvHtJyI18Yz+7tVI3u5XM=";
          };

      runtimeLibs = with pkgs; [ libsecret ];
    in
    {
      home.packages = [
        (pkgs.stdenv.mkDerivation {
          pname = "proton-drive";
          inherit version src;

          dontUnpack = true;

          nativeBuildInputs =
            if pkgs.stdenv.isLinux
            then [ pkgs.autoPatchelfHook pkgs.makeWrapper ]
            else [ pkgs.makeWrapper ];

          buildInputs = lib.optionals pkgs.stdenv.isLinux runtimeLibs;

          installPhase = ''
            runHook preInstall

            install -m755 -D $src $out/bin/proton-drive

            ${lib.optionalString pkgs.stdenv.isLinux ''
              wrapProgram $out/bin/proton-drive \
                --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
            ''}

            runHook postInstall
          '';
        })
      ];
    };
}
