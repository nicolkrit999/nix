{ delib, inputs, pkgs, lib, ... }:
let
  src = inputs.tgt;

  # tdlib-rs (Cargo.lock) generates bindings for one exact TDLib API; remove the pin when nixpkgs tdlib matches tdlib-rs's TDLIB_VERSION.
  tdlib = pkgs.tdlib.overrideAttrs {
    version = "1.8.61";
    src = pkgs.fetchFromGitHub {
      owner = "tdlib";
      repo = "td";
      rev = "11e254af695060d8890024dd7faa1cc2d6685ef8";
      hash = "sha256-h69eamdx9f1XR0XFw/8mZqOcjWkjRMHE/CVKVESGBg8=";
    };
  };

  tgt = pkgs.rustPlatform.buildRustPackage {
    pname = "tgt";
    version = "${(lib.importTOML "${src}/Cargo.toml").package.version}-unstable-${builtins.substring 0 8 src.lastModifiedDate}";
    inherit src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    buildNoDefaultFeatures = true;
    buildFeatures = [ "pkg-config" "voice-message" "rodio" ];

    nativeBuildInputs = with pkgs; [ pkg-config cmake makeWrapper ];
    buildInputs = [ tdlib ] ++ (with pkgs; [ openssl alsa-lib libopus ]);

    postPatch = ''
      substituteInPlace src/configs/custom/mod.rs \
        --replace-fail 'option_env!("CARGO_MANIFEST_DIR")?' '"${placeholder "out"}/share/tgt"'
    '';

    preBuild = ''
      export HOME=$TMPDIR
    '';

    doCheck = false;

    postInstall = ''
      mkdir -p $out/share/tgt
      cp -r config $out/share/tgt/
      wrapProgram $out/bin/tgt --run '
        if [ -d "$HOME/.tgt" ]; then d="$HOME/.tgt/config"; else d="''${XDG_CONFIG_HOME:-$HOME/.config}/tgt/config"; fi
        mkdir -p "$d" && cp -rn --no-preserve=mode '"$out"'/share/tgt/config/. "$d"/ 2>/dev/null || true
      '
    '';

    meta = {
      description = "TUI for Telegram written in Rust";
      homepage = "https://github.com/FedericoBruzzone/tgt";
      license = with lib.licenses; [ mit asl20 ];
      mainProgram = "tgt";
    };
  };
in
delib.module {
  name = "programs.tgt";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ tgt ];
  };
}
