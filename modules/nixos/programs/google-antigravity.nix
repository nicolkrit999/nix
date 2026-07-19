{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.google-antigravity";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.overlays = [ inputs.antigravity-nix.overlays.default ];
    environment.systemPackages = [
      (pkgs.google-antigravity-no-fhs.override {
        useSystemChromeProfile = true;
      })
      pkgs.google-chrome
    ];
  };
}
