{ pkgs, lib, ... }:
let
  myVivaldi = pkgs.vivaldi.override {
    commandLineArgs = "--password-store=kwallet6 --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
  };
in
{
  nixpkgs.config = {
    allowUnfree = true;
    vivaldi = {
      proprietaryCodecs = true;
      enableWideVine = true;
    };
  };

  environment.systemPackages = [
    myVivaldi
  ];
}
