# Proton Drive CLI - official Bun-compiled single-file executable
# Reference: https://proton.me/drive/download
#
# The CLI is a Bun standalone executable. Bun locates its embedded JS payload
# via /proc/self/exe plus a byte-offset trailer at the end of the file, so the
# binary MUST NOT be modified. patchelf rewrites the ELF, shifts the file
# layout, invalidates that offset, and Bun silently degrades to the bare Bun
# CLI -- at which point `proton-drive auth login` is parsed as the reserved
# `bun auth` subcommand and errors out. We therefore run the pristine binary
# inside an FHS sandbox that supplies the standard dynamic linker and libsecret
# (dlopen'd at runtime), leaving the executable byte-for-byte untouched. This is
# self-contained and does not depend on programs.nix-ld (off on some hosts).
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

      # Pristine, unmodified Linux binary placed in the store (no patchelf).
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

      # macOS uses a native Mach-O binary; dyld resolves libraries natively and
      # secrets go through the Keychain, so no FHS/patchelf shenanigans needed.
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
        (if pkgs.stdenv.isLinux then linuxPackage else darwinPackage)
      ];
    };
}
