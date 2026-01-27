{ pkgs, lib, vars, ... }:
let
  needsGnomeKeyring =
    (vars.hyprland or false) ||
    (vars.niri or false) ||
    (vars.gnome or false) ||
    (vars.cosmic or false);
  passwordStore = if needsGnomeKeyring then "gnome" else "kwallet6";

  myVivaldi = pkgs.vivaldi.override {
    commandLineArgs = "--password-store=${passwordStore} --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
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
