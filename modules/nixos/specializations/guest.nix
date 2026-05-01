{ delib
, lib
, config
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;

  guestWelcomeScript = pkgs.writeShellScriptBin "guest-welcome" ''
    # Wait for panel/notifications stack so the dialog isn't drawn under it.
    sleep 3
    ${pkgs.zenity}/bin/zenity --warning \
      --title="Sessione Ospite" \
      --width=420 \
      --text="<span size='large' weight='bold'>Sessione temporanea</span>\n\nTutti i dati verranno cancellati al riavvio.\nSalvare i file importanti su una chiavetta USB o servizio cloud."
  '';
in
delib.module {
  name = "specializations.guest";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;

    specialisation.guest.configuration = {
      system.nixos.tags = [ "guest" ];

      services.displayManager.autoLogin = {
        enable = lib.mkForce true;
        user = lib.mkForce "guest";
      };
      services.displayManager.defaultSession = lib.mkForce "xfce";

      myconfig.programs.hyprland.enable = lib.mkForce false;
      myconfig.programs.niri.enable = lib.mkForce false;
      myconfig.programs.mango.enable = lib.mkForce false;
      myconfig.programs.gnome.enable = lib.mkForce false;
      myconfig.programs.kde.enable = lib.mkForce false;
      myconfig.programs.cosmic.enable = lib.mkForce false;
      myconfig.programs.caelestia.enable = lib.mkForce false;
      myconfig.programs.noctalia.enable = lib.mkForce false;

      services.xserver.desktopManager.xfce = {
        enable = lib.mkForce true;
        enableScreensaver = false;
      };

      myconfig.services.hyprlock.enable = lib.mkForce false;
      myconfig.services.hypridle.enable = lib.mkForce false;
      myconfig.services.swaync.enable = lib.mkForce false;

      myconfig.programs.nix-ld.enable = lib.mkForce false;
      myconfig.programs.nix-alien.enable = lib.mkForce false;
      myconfig.programs.claude-code.enable = lib.mkForce false;
      myconfig.programs.claude-desktop.enable = lib.mkForce false;
      myconfig.bluetooth.enable = lib.mkForce false;

      myconfig.stylix.enable = lib.mkForce false;
      myconfig.constants.theme.catppuccin = lib.mkForce false;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      stylix.image = lib.mkForce (pkgs.writeText "dummy-image.png" "");

      # Re-declare stylix.enable inside home-manager so disabled per-WM
      # stylix targets (e.g. stylix-niri, stylix-hyprland) short-circuit
      # before reading options that no longer exist. Same pattern as
      # safe-mode.nix.
      home-manager.users.${myUserName} =
        { lib, ... }:
        {
          options.stylix.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          config.stylix.enable = lib.mkForce false;
        };

      users.users.guest = {
        isNormalUser = true;
        description = "Guest Account";
        uid = 2000;
        group = "guest";
        extraGroups = [ "networkmanager" "audio" "video" ];
        # Vestigial — autologin makes this irrelevant. Public ("guest")
        # password kept so PAM/polkit don't see a locked account.
        hashedPassword = "$6$Cqklpmh3CX0Cix4Y$OCx6/ud5bn72K.qQ3aSjlYWX6Yqh9XwrQHSR1GnaPRud6W4KcyU9c3eh6Oqn7bjW3O60oEYti894sqVUE1e1O0";
        createHome = true;
      };
      users.groups.guest.gid = 2000;

      fileSystems."/home/guest" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=25%"
          "mode=700"
          "uid=2000"
          "gid=2000"
          "nosuid"
          "nodev"
          "noatime"
        ];
      };

      # `\n` is interpreted as a literal newline by systemd-tmpfiles;
      # the doubled backslash survives nix string parsing.
      systemd.tmpfiles.rules = [
        "d /var/lib/AccountsService/users 0755 root root -"
        "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
        "f /home/.hidden 0644 root root - guest"
        # Commented out: skel copy may be the cause of black screen on
        # autologin (races with xfce session, or seeds bad displays.xml
        # for the laptop's HiDPI panel). Removing it makes xfce fall
        # back to the first-run dialog, which is the diagnostic we want.
        # "C /home/guest/.config 0700 2000 2000 - ${guestConfigSkel}"
      ];

      networking.firewall.extraCommands = ''
        iptables -A OUTPUT -m owner --uid-owner 2000 -o tailscale0 -j REJECT
        iptables -A OUTPUT -m owner --uid-owner 2000 -d 100.64.0.0/10 -j REJECT
      '';

      systemd.slices."user-2000".sliceConfig = {
        MemoryMax = "4G";
        CPUWeight = 90;
      };

      environment.systemPackages = with pkgs; [
        (firefox.override {
          extraPolicies = {
            DisableFirstRunPage = true;
            DontCheckDefaultBrowser = true;
            DisableTelemetry = true;
            DisablePocket = true;
          };
        })
        xfce.mousepad
        xfce.xfce4-screenshooter
        file-roller
        zenity
      ];

      environment.etc."xdg/autostart/guest-welcome.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Guest Welcome
        Exec=${guestWelcomeScript}/bin/guest-welcome
        OnlyShowIn=XFCE;
        X-GNOME-Autostart-enabled=true
        NoDisplay=false
        Terminal=false
      '';
    };
  };
}
