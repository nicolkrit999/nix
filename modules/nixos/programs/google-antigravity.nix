{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.google-antigravity";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [
      (inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-no-fhs.override {
        useSystemChromeProfile = true;
      })
      pkgs.google-chrome
    ];
  };
}
