{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.google-antigravity";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.overlays = [ inputs.antigravity-nix.overlays.default ];
    environment.systemPackages = [
      (pkgs.passwordStoreWrap (pkgs.google-antigravity-no-fhs.override {
        useUserProfile = true;
      }))
      pkgs.google-chrome
    ];
  };
}
