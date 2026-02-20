{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "kde";
  options.kde = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      cfg,
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
