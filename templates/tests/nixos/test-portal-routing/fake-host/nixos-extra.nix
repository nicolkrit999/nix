# Plain NixOS bits of the portal fake host: platform, HM user base, stylix off, and what real
# hosts get from modules this fake host does not load: the xserver desktops (guest/safemode
# specialisations), HM Hyprland (hyprland-main.nix) and gnome-keyring, whose package lands in
# xdg.portal.extraPortals (common-configuration-nixos.nix). The drift check in the check
# script fails when these stop matching the real hosts.
{ inputs, lib, ... }:
let
  case = builtins.fromJSON (builtins.getEnv "PORTAL_CASE");
  on = n: builtins.elem n case.desktops;
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
  stylix.enable = false;
  services.gnome.gnome-keyring.enable = true;
  documentation.enable = false;

  services.xserver = lib.mkIf (on "xfce" || on "icewm") {
    enable = true;
    desktopManager.xfce.enable = on "xfce";
    windowManager.icewm.enable = on "icewm";
  };

  home-manager.users.krit = {
    home = {
      username = "krit";
      homeDirectory = "/home/krit";
      stateVersion = "25.11";
    };
    manual.manpages.enable = false;
    wayland.windowManager.hyprland.enable = case.hmPortal;
  };
}
