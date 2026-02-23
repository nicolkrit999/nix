{
  delib,
  pkgs,
  ...
}:
delib.module {
  # TODO: probably can be renamed to "programs.kde" so that it's not enabled at all if the user does not want it
  name = "kde";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
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
