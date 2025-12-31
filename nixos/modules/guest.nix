{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

let
  guestUid = 2000;

  guestWarningScript = pkgs.writeShellScriptBin "guest-warning" ''
    if [ "$USER" != "guest" ]; then exit 0; fi

    # Do not show this warning if the user logged in a session where it doesn't have access to
    if [[ "$XDG_CURRENT_DESKTOP" != *"XFCE"* ]]; then exit 0; fi

    sleep 3
    ${pkgs.zenity}/bin/zenity --warning \
      --title="Guest Mode / Modalità ospite" \
      --text="<span size='large' weight='bold'>⚠️  Warning: Temporary Session</span>\n\nThis is a guest session.\nAll files, downloads, and settings will be \n<span color='red'>PERMANENTLY DELETED</span> when you restart the computer.\n\n──────────────────────────────\n\n<span size='large' weight='bold'>⚠️  Attenzione: Sessione temporanea</span>\n\nQuesta è una sessione ospite.\nTutti i file, download e impostazioni VERRANNNO <span color='red'>CANCELLATI PERMANENTEMENTE</span> al riavvio del computer." \
      --width=500
  '';
in
{
  config = lib.mkIf vars.guest {

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
      shell = pkgs.bash;
    };

    users.groups.guest = {
      gid = guestUid;
    };

    # 🚫 DISABLE "SWITCH USER" (Force Logout)
    # Point the system-wide kioskrc to ensure XFCE picks it up.
    environment.etc."xdg/xfce4/kiosk/kioskrc".text = ''
      [xfce4-session]
      SwitchUser=root
      SaveSession=NONE
    '';

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

    # 🖥️ DESKTOP ENVIRONMENT
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    # 🎯 FORCE XFCE DEFAULT
    systemd.tmpfiles.rules = [
      "d /var/lib/AccountsService/users 0755 root root -"
      "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
    ];

    # 📦 GUEST PACKAGES
    environment.systemPackages = with pkgs; [
      (google-chrome.override {
        commandLineArgs = "--no-first-run --no-default-browser-check";
      })
      nemo
      eog
      file-roller
      gnome-calculator
      zenity
    ];

    # ⚠️ AUTOSTART WARNING
    environment.etc."xdg/autostart/guest-warning.desktop".text = ''
      [Desktop Entry]
      Name=Guest Warning
      Exec=${guestWarningScript}/bin/guest-warning
      Type=Application
      Terminal=false
      OnlyShowIn=XFCE;
    '';

    # 🛡️ FIREWALL
    networking.firewall.extraCommands = lib.mkIf config.services.tailscale.enable ''
      iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -o tailscale0 -j REJECT
      iptables -A OUTPUT -m owner --uid-owner ${toString guestUid} -d 100.64.0.0/10 -j REJECT
    '';

    # 🔒 POLKIT
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "guest") {
          if (action.id.indexOf("org.freedesktop.udisks2.filesystem-mount-system") == 0) {
            return polkit.Result.NO;
          }
          if (action.id.indexOf("org.freedesktop.login1.suspend") == 0 ||
              action.id.indexOf("org.freedesktop.login1.hibernate") == 0) {
            return polkit.Result.NO;
          }
        }
      });
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
