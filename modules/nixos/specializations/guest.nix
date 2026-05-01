{ delib
, lib
, config
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
  guestConfigSkel = pkgs.runCommand "guest-xfce-config-skel" { } ''
    d=$out/xfce4/xfconf/xfce-perchannel-xml
    mkdir -p $d

    cat > $d/xfce4-panel.xml <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-panel" version="1.0">
      <property name="configver" type="int" value="2"/>
    </channel>
    EOF

    cat > $d/displays.xml <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="displays" version="1.0">
      <property name="Notify" type="bool" value="false"/>
      <property name="ActiveProfile" type="string" value="Default"/>
    </channel>
    EOF

    cat > $d/xfce4-session.xml <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-session" version="1.0">
      <property name="general" type="empty">
        <property name="SaveOnExit" type="bool" value="false"/>
        <property name="PromptOnLogout" type="bool" value="false"/>
      </property>
      <property name="splash" type="empty">
        <property name="Engine" type="string" value=""/>
      </property>
    </channel>
    EOF
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
        "C /home/guest/.config 0700 2000 2000 - ${guestConfigSkel}"
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
      ];
    };
  };
}
