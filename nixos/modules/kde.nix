{
  pkgs,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.kde or false) {

    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      oxygen # Theme
      khelpcenter # Help Center
      konsole # Terminal
      okular # Document viewer
      elisa # Music player
      discover # Software center

      # Kwallet mandatory to ensure that only gnome-keyring is enabled
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

    /*
        # 🛡️ SECURITY WRAPPER: Block guest user from KDE (Wayland & X11)
        environment.etc."xdg/autostart/guest-block-kde.desktop".text = ''
          [Desktop Entry]
          Name=Block Guest from KDE
          Exec=${pkgs.writeShellScript "kick-guest" ''
            # 1. Check if user is guest
            if [ "$USER" = "guest" ]; then

               # 2. Aggressive Check: Matches "KDE", "Plasma", "KDE-Wayland", etc.
               if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Plasma"* ]]; then

                  # Show warning
                  ${pkgs.zenity}/bin/zenity --error --text="❌ ACCESS DENIED\n\nGuest is restricted to XFCE." --width=300

                  # Try specific KDE logout command
                  ${pkgs.kdePackages.qttools}/bin/qdbus org.kde.Shutdown /Shutdown logout

                  # Fallback: Kill the session
                  sleep 2
                  ${pkgs.systemd}/bin/loginctl terminate-session $XDG_SESSION_ID

                  # Ultimate Fallback: Kill the user
                  sleep 2
                  ${pkgs.systemd}/bin/loginctl terminate-user guest
               fi
            fi
          ''}
          Type=Application
          OnlyShowIn=KDE;
          NoDisplay=true
        '';
    */
  };
}
