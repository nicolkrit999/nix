{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-desktop";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs
    ];
  };
}
