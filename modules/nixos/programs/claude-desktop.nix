{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-desktop";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
    environment.systemPackages = [ pkgs.claude-desktop-fhs ];
  };
}
