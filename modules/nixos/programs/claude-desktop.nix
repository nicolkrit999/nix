{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;

  # The claude-desktop app itself stays pinned to nixpkgs-2511 (25.11) because
  # upstream's pkgs/claude-desktop.nix uses `nodePackages.asar`, removed in 26.05.
  claude-desktop-app = inputs.claude-desktop.packages.${system}.claude-desktop;

  # Rebuild the FHS wrapper ourselves with SYSTEM pkgs (26.05) instead of using
  # upstream's `claude-desktop-with-fhs`. Upstream bundles `docker` into the FHS
  # sandbox; pulled from the 25.11 pin that resolves to docker_28, which is now
  # marked insecure (unmaintained since Nov 2025). Building the FHS env from
  # system pkgs gets a secure docker (docker_29) while keeping the pinned app.
  # Mirrors upstream flake.nix's claude-desktop-with-fhs verbatim otherwise.
  claude-desktop-with-fhs = pkgs.buildFHSEnv {
    name = "claude-desktop";
    targetPkgs = p: with p; [
      docker
      glibc
      openssl
      nodejs
      uv
    ];
    runScript = "${claude-desktop-app}/bin/claude-desktop";
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      cp ${claude-desktop-app}/share/applications/claude.desktop $out/share/applications/

      mkdir -p $out/share/icons
      cp -r ${claude-desktop-app}/share/icons/* $out/share/icons/
    '';
  };
in
delib.module {
  name = "programs.claude-desktop";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ claude-desktop-with-fhs ];
  };
}
