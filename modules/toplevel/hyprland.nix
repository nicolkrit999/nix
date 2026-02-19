{
  pkgs,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.hyprland or true) {
    programs.hyprland = {
      enable = true;
      withUWSM = true;

      /*
            # 🛡️ SECURITY WRAPPER: Block guest user to login into hyprland even if it is selected in sddm
            package = pkgs.hyprland.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                mv $out/bin/Hyprland $out/bin/Hyprland-real

                # This config launches NOTHING except the warning, then exits when you close it.
                cat <<CONF > $out/bin/hyprland-guest.conf
                monitor=,preferred,auto,1
                misc {
                    disable_hyprland_logo = true
                    disable_splash_rendering = true
                }
                # Run Zenity, wait for it to close, then kill Hyprland
                exec-once = ${pkgs.zenity}/bin/zenity --error --width=500 --text="<span size='large' weight='bold'>❌ ACCESS DENIED / ACCESSO NEGATO</span>\n\nThe Guest user is restricted to the XFCE Desktop Environment.\nPlease select 'Xfce Session' at the login screen.\n\n──────────────────────────────\n\nL'utente ospite è limitato all'ambiente desktop XFCE.\nPer favore seleziona 'Sessione Xfce' nella schermata di login."; $out/bin/hyprctl dispatch exit
                CONF

                # 2. Create the Wrapper Script
                cat <<EOF > $out/bin/Hyprland
                #!/bin/sh
                if [ "\$USER" = "guest" ]; then
                   # Launch Hyprland using the Trap Config
                   exec $out/bin/Hyprland-real -c $out/bin/hyprland-guest.conf
                fi
                # Normal launch for everyone else
                exec $out/bin/Hyprland-real "\$@"
                EOF

                chmod +x $out/bin/Hyprland
              '';
            });
      */
    };

    security.pam.services.hyprlock = { };
  };
}
