{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.kde";

  nixos.ifEnabled =
    {
      myconfig,
      ...
    }:
    {
      services.desktopManager.plasma6.enable = true;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        oxygen
        khelpcenter
        konsole
        okular
        elisa
        discover
        kwallet
        kwallet-pam
        kwalletmanager
      ];

      environment.etc."xdg/kwalletrc".text = ''
        [Wallet]
        First Use=false
        Enabled=false
        [org.freedesktop.secrets]
        apiEnabled=false
      '';
    };
}
