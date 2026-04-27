{ delib
, config
, pkgs
, lib
, ...
}:
delib.module {
  name = "guest";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    let
      guestUid = 2000;

      # Pre-seeded XFCE config to suppress all first-run setup dialogs.
      guestXfceConfigSkel = pkgs.runCommand "guest-xfce-config-skel" { } ''
        mkdir -p $out/xfce4/xfconf/xfce-perchannel-xml

        # Suppress panel first-run / layout dialog
        cat > $out/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<'EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-panel" version="1.0">
          <property name="configver" type="int" value="2"/>
        </channel>
        EOF

        # Suppress display setup helper (xfce4-display-settings --minimal)
        cat > $out/xfce4/xfconf/xfce-perchannel-xml/displays.xml <<'EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="displays" version="1.0">
        </channel>
        EOF

        # Suppress session save/restore dialog, disable crash recovery prompt
        cat > $out/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml <<'EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-session" version="1.0">
          <property name="general" type="empty">
            <property name="SaveOnExit" type="bool" value="false"/>
            <property name="PromptOnLogout" type="bool" value="false"/>
          </property>
          <property name="startup" type="empty">
            <property name="screensaver-manager" type="string" value=""/>
          </property>
        </channel>
        EOF
      '';

      # 🛡️ THE MONITOR SCRIPT (reboot if on non-XFCE session)
      guestMonitorScript = pkgs.writeShellScriptBin "guest-monitor" ''
        # Safety check: Only run for guest
        if [ "$USER" != "guest" ]; then exit 0; fi

        # 1. CHECK SESSION TYPE
        IS_XFCE=false
        if [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]] || \
           [[ "$DESKTOP_SESSION" == *"xfce"* ]] || \
           [[ "$GDMSESSION" == *"xfce"* ]]; then
           IS_XFCE=true
        fi

        # 2. ACT ACCORDINGLY
        if [ "$IS_XFCE" = true ]; then
           # ✅ WE ARE IN XFCE (ALLOWED)
           sleep 2
           ${pkgs.zenity}/bin/zenity --warning \
             --title="Guest Mode" \
             --text="<span size='large' weight='bold'>⚠️  Guest Session</span>\n\nAll files will be deleted on reboot." \
             --width=400
        else
           # ❌ WE ARE NOT IN XFCE (FORBIDDEN)

           # Show warning in background. User cannot stop what is coming.
           ${pkgs.zenity}/bin/zenity --error \
             --title="Access Denied" \
             --text="<span size='large' weight='bold'>❌ ACCESS DENIED</span>\n\nGuest is restricted to XFCE.\n\n<b>System will reboot in 5 seconds.</b>" \
             --width=400 &

           # Wait 5 seconds
           sleep 5

           # 3. REBOOT THE COMPUTER
           # This is the only way to safely reset the GPU/Drivers from a forbidden Wayland session
           # without causing a black screen hang.
           sudo reboot
        fi
      '';
    in
    {
      users.users.guest = {
        isNormalUser = true;
        description = "Guest Account";
        uid = guestUid;
        group = "guest";
        extraGroups = [
          "networkmanager"
          "audio"
          "video"
        ];
        hashedPassword = "$6$Cqklpmh3CX0Cix4Y$OCx6/ud5bn72K.qQ3aSjlYWX6Yqh9XwrQHSR1GnaPRud6W4KcyU9c3eh6Oqn7bjW3O60oEYti894sqVUE1e1O0";
        createHome = true;
      };

      users.groups.guest.gid = guestUid;

      # 🧹 EPHEMERAL HOME
      fileSystems."/home/guest" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=25%"
          "mode=700"
          "uid=${toString guestUid}"
          "gid=${toString guestUid}"
        ];
      };

      # 🎯 FORCE XFCE PREFERENCE + PRE-SEED CONFIG
      systemd.tmpfiles.rules = [
        "d /var/lib/AccountsService/users 0755 root root -"
        "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
        "f /home/.hidden 0644 root root - guest"
        "C /home/guest/.config 0700 ${toString guestUid} ${toString guestUid} - ${guestXfceConfigSkel}"
      ];

      # 🖥️ DESKTOP ENVIRONMENT
      services.xserver.desktopManager.xfce.enable = true;

      # 📦 GUEST PACKAGES
      environment.systemPackages = with pkgs; [
        (firefox.override {
          extraPolicies = {
            DisableFirstRunPage = true;
            DontCheckDefaultBrowser = true;
            DisableTelemetry = true;
          };
        })
        iptables # Firewall management (for the enforcement script)
        file-roller # Archive manager
        zenity # keep for the startup warning
      ];

      environment.xfce.excludePackages = [ pkgs.xfce.parole ];

      environment.etc."xdg/autostart/guest-monitor.desktop".text = ''
        [Desktop Entry]
        Name=Guest Session Monitor
        Exec=${guestMonitorScript}/bin/guest-monitor
        Type=Application
        Terminal=false
      '';

      # 🔓 SUDO RULES FOR REBOOT
      # We allow the guest to run 'reboot' without a password.
      # This is necessary for the enforcement script.
      security.sudo.extraRules = [
        {
          users = [ "guest" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/reboot";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      # 🛡️ FIREWALL
      networking.firewall.extraCommands = lib.mkIf config.services.tailscale.enable ''
        iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -o tailscale0 -j REJECT
        iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -d 100.64.0.0/10 -j REJECT
      '';

      # ⚖️ LIMITS
      systemd.slices."user-${toString guestUid}" = {
        sliceConfig = {
          MemoryMax = "4G";
          CPUWeight = 90;
        };
      };
    };
}
