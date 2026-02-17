{ pkgs, lib }:
# "Multi functional app to find duplicates, empty folders, similar images etc. "
# Reference: https://github.com/qarmin/czkawka
let
  runtimeLibs = with pkgs; [
    glib
    gtk4
    libadwaita
    fontconfig
    freetype
    libxkbcommon
    libGL
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libxcb
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
  ];
in
pkgs.stdenv.mkDerivation rec {
  pname = "krokiet";
  version = "10.0.0";

  src = pkgs.fetchurl {
    url = "https://github.com/qarmin/czkawka/releases/download/${version}/linux_krokiet_x86_64";
    sha256 = "048ch85j1pmp1y7riscrprb08q2ikxjbz7wfc6a5kwrxlx8qhdia";
  };

  iconSrc = ../../src/svg-images/utilities/czkawka-krokiet_logo.svg;

  dontUnpack = true;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
  ];

  buildInputs = runtimeLibs;

  installPhase = ''
    runHook preInstall

    # 1. Install the binary
    install -m755 -D $src $out/bin/krokiet

    # 2. Install the Icon (Standard Linux Path)
    install -m644 -D $iconSrc $out/share/icons/hicolor/scalable/apps/krokiet.svg

    # 3. Wrap the binary
    wrapProgram $out/bin/krokiet \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    # 4. Create the .desktop file (Updated Icon Name)
    mkdir -p $out/share/applications
    cat > $out/share/applications/krokiet.desktop <<EOF
    [Desktop Entry]
    Name=Krokiet
    Comment=Czkawka Slint Frontend
    Exec=krokiet
    Icon=krokiet
    Terminal=false
    Type=Application
    Categories=System;Utility;
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Slint frontend for Czkawka (Binary v10)";
    homepage = "https://github.com/qarmin/czkawka";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "krokiet";
  };
}
