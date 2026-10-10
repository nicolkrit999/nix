{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.kde";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.desktopManager.plasma6.enable = true;

    security.wrappers.kwin_wayland.capabilities = lib.mkForce "";

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      oxygen
      khelpcenter
      konsole
      okular
      elisa
      discover
    ];

    # kwallet, kwallet-pam and kwalletmanager are hard requirements of
    # plasma6 and cannot be excluded. The KWallet login pieces are masked
    # below instead.
    systemd.user.services.plasma-kwallet-pam.enable = false;

    # kwalletd6 stays on as a thin frontend that wraps the Secret Service
    # (gnome-keyring), so KIO, plasma-nm and QtKeychain apps keep working.
    # ksecretd, the KDE Secret Service store, is off so that gnome-keyring is
    # the only org.freedesktop.secrets provider.
    environment.etc."xdg/kwalletrc".text = ''
      [Wallet]
      First Use=false
      Enabled=true
      [KSecretD]
      Enabled=false
      [org.freedesktop.secrets]
      apiEnabled=false
      [Migration]
      MigrateTo3rdParty=false
    '';
  };

  home.ifEnabled = {
    # PAM kwallet is forced off, so the PAM-driven wallet init is a no-op.
    xdg.configFile."autostart/pam_kwallet_init.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=pam_kwallet_init
      Hidden=true
    '';
  };
}
