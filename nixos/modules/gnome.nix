{
  pkgs,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.gnome or false) {

    services.desktopManager.gnome.enable = true;

    # 2. Exclude default bloatware
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour # Onboarding
      epiphany # Default browser
      geary # Email
      totem # Video player
      yelp # Help viewer
    ];

    /*
      # 3. 🛡️ SECURITY WRAPPER: Block guest user from GNOME
      environment.etc."xdg/autostart/guest-block-gnome.desktop".text = ''
        [Desktop Entry]
        Name=Block Guest from GNOME
        Exec=${pkgs.writeShellScript "kick-guest-gnome" ''
          # 1. Check if user is guest
          if [ "$USER" = "guest" ]; then

             # 2. Check if the session is GNOME
             if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then

                # Show warning using Zenity
                ${pkgs.zenity}/bin/zenity --error --width=300 \
                  --text="❌ ACCESS DENIED\n\nThe Guest account is restricted to XFCE.\nYou have been logged out."

                # 3. Force Logout
                # Try GNOME specific logout
                ${pkgs.gnome-session}/bin/gnome-session-quit --no-prompt --logout

                # Fallback: Kill the session
                sleep 2
                ${pkgs.systemd}/bin/loginctl terminate-session $XDG_SESSION_ID

                # Ultimate Fallback: Kill the user processes
                sleep 2
                ${pkgs.systemd}/bin/loginctl terminate-user guest
             fi
          fi
        ''}
        Type=Application
        OnlyShowIn=GNOME;
        NoDisplay=true
      '';
    */

    # 4. 🔧 CONFLICT RESOLUTION (SSH Askpass)
    # Depending on the primary de (gnome vs kde) then use ksshaskpass (kde) or seahorse (gnome).
    # Hyprland does not provide one. If the main is hyprland then choose either one based on user preference.
    programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  };
}
