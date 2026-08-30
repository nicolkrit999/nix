{ delib
, lib
, pkgs
, ...
}:
let
  asus = {
    make = "ASUSTek COMPUTER INC";
    model = "PG32UCDP";
    serial = "SALMQS185801";
  };
  lg = {
    make = "LG Electronics";
    model = "27GN950";
    serial = "202NTWGFH113";
  };

  hyprDesc = m: "desc:${m.make} ${m.model} ${m.serial}";

  niriKey = m: "${m.make} ${m.model} ${m.serial}";

  resolveMonitorBySerial = pkgs.writeShellScript "resolve-monitor-by-serial" ''
    set -euo pipefail
    serial="$1"
    if command -v niri >/dev/null 2>&1 && niri msg -j outputs >/dev/null 2>&1; then
      niri msg -j outputs \
        | ${pkgs.jq}/bin/jq -r --arg s "$serial" \
            'to_entries[] | select(.value.serial == $s) | .key' \
        | head -n1
    elif command -v hyprctl >/dev/null 2>&1 && hyprctl monitors -j >/dev/null 2>&1; then
      hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -r --arg s "$serial" \
            '.[] | select(.serial == $s) | .name' \
        | head -n1
    fi
  '';

  monitorBySerial = m: "$(${resolveMonitorBySerial} ${m.serial})";
in
delib.module {
  name = "krit.specializations.home";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.home.configuration = {
      system.nixos.tags = [ "home" ];

      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      myconfig.programs.mango.enable = lib.mkForce false;

      myconfig.constants.wallpapers = lib.mkForce [
        {
          targetMonitor = "eDP-1";
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";
        }
        {
          targetMonitor = monitorBySerial lg;
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
          wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
        }
        {
          targetMonitor = monitorBySerial asus;
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";
        }
      ];

      myconfig.programs.hyprland.monitors = lib.mkForce [
        { output = "eDP-1"; mode = "3200x2000@120"; position = "4000x560"; scale = 1.6; }
        { output = hyprDesc lg; mode = "3840x2160@144"; position = "0x0"; scale = 1.5; transform = 1; bitdepth = 10; }
        { output = hyprDesc asus; mode = "3840x2160@240"; position = "1440x560"; scale = 1.5; bitdepth = 10; }
      ];

      myconfig.programs.hyprland.monitorWorkspaces = lib.mkForce [
        { workspace = "1"; monitor = hyprDesc asus; }
        { workspace = "2"; monitor = hyprDesc asus; }
        { workspace = "3"; monitor = hyprDesc asus; }
        { workspace = "4"; monitor = hyprDesc asus; }
        { workspace = "5"; monitor = hyprDesc asus; }
        { workspace = "6"; monitor = hyprDesc lg; }
        { workspace = "7"; monitor = hyprDesc lg; }
        { workspace = "8"; monitor = hyprDesc lg; }
        { workspace = "9"; monitor = hyprDesc lg; }
        { workspace = "10"; monitor = hyprDesc lg; }
      ];

      myconfig.programs.hyprland.windowRules = lib.mkForce [
        { match.class = "^(nvim)$"; workspace = "2"; }
        { match.class = "^(yazi)$"; workspace = "3"; }
        { match.class = "^(kitty)$"; workspace = "8"; }
        { match.class = "^(code)$"; workspace = "2 silent"; }
        { match.class = "^(nvim-editor)$"; workspace = "2 silent"; }
        { match.class = "^(org.kde.kate)$"; workspace = "2 silent"; }
        { match.class = "^(jetbrains-pycharm-ce)$"; workspace = "2 silent"; }
        { match.class = "^(jetbrains-Clion)$"; workspace = "2 silent"; }
        { match.class = "^(jetbrains-idea-ce)$"; workspace = "2 silent"; }
        { match.class = "^(org.kde.dolphin)$"; workspace = "3 silent"; }
        { match.class = "^(thunar)$"; workspace = "3 silent"; }
        { match.class = "^(yazi)$"; workspace = "3 silent"; }
        { match.class = "^(ranger)$"; workspace = "3 silent"; }
        { match.class = "^(org.gnome.Nautilus)$"; workspace = "3 silent"; }
        { match.class = "^(nemo)$"; workspace = "3 silent"; }
        { match.class = "^(winboat)$"; workspace = "7 silent"; }
        { match.class = "^(Actual)$"; workspace = "10 silent"; }
        { match.class = "^(org.jellyfin.JellyfinDesktop)$"; workspace = "6 silent"; }
        { match.class = "^(chromium-browser)$"; workspace = "6 silent"; }
        { match.class = "^(brave-browser)$"; workspace = "6 silent"; }
        { match.class = "^(brave-.*\\..*)$"; workspace = "6 silent"; }
        { match.class = "(?i)spotify"; workspace = "6 silent"; }
        { match.class = "^(kitty)$"; workspace = "8 silent"; }
        { match.class = "^(alacritty)$"; workspace = "8 silent"; }
        { match.class = "^(foot)$"; workspace = "8 silent"; }
        { match.class = "^(xfce4-terminal)$"; workspace = "8 silent"; }
        { match.class = "^(com.system76.CosmicTerm)$"; workspace = "8 silent"; }
        { match.class = "^(org.kde.konsole)$"; workspace = "8 silent"; }
        { match.class = "^(gnome-terminal)$"; workspace = "8 silent"; }
        { match.class = "^(XTerm)$"; workspace = "8 silent"; }
        { match.class = "^(vesktop)$"; workspace = "9 silent"; }
        { match.class = "^(org.telegram.desktop)$"; workspace = "9 silent"; }
        { match.class = "^(whatsapp-electron)$"; workspace = "9 silent"; }
        { match.class = "^(com.rtosta.zapzap)$"; workspace = "9 silent"; }

        { match.class = "^(scratch-term)$"; float = true; }
        { match.class = "^(scratch-term)$"; center = true; }
        { match.class = "^(scratch-term)$"; size = "80% 80%"; }
        { match.class = "^(scratch-term)$"; workspace = "special:magic"; }
        { match.class = "^(scratch-fs)$"; float = true; }
        { match.class = "^(scratch-fs)$"; center = true; }
        { match.class = "^(scratch-fs)$"; size = "80% 80%"; }
        { match.class = "^(scratch-fs)$"; workspace = "special:magic"; }
        { match.class = "^(scratch-browser)$"; float = true; }
        { match.class = "^(scratch-browser)$"; center = true; }
        { match.class = "^(scratch-browser)$"; size = "80% 80%"; }
        { match.class = "^(scratch-browser)$"; workspace = "special:magic"; }

        { match.class = "^winboat-.*$"; workspace = "7"; }
        { match.class = "^winboat-.*$"; suppress_event = "fullscreen maximize activate activatefocus"; }
        { match.class = "^winboat-.*$"; no_initial_focus = true; }
        { match.class = "^winboat-.*$"; no_anim = true; }
        { match.class = "^winboat-.*$"; rounding = 0; }
        { match.class = "^winboat-.*$"; no_shadow = true; }
        { match.class = "^winboat-.*$"; no_blur = true; }
        { match.class = "^winboat-.*$"; opaque = true; }
      ];

      myconfig.programs.hyprland.execOnce = lib.mkForce [
        "hyprctl dispatch workspace 1"
        "[workspace 1 silent] zen-beta"
        "[workspace 2 silent] kitty --class nvim -e nvim"
        "[workspace 3 silent] kitty --class yazi -e yazi"
        "[workspace 8 silent] kitty"
        "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
      ];

      myconfig.programs.waybar-hyprland.waybarWorkspaceIcons = lib.mkForce {
        "1" = "";
        "2" = ":";
        "3" = ":";
        "4" = "";
        "5" = "";
        "6" = ":";
        "7" = "";
        "8" = ":";
        "9" = ":󰭹";
        "10" = ":";
        "magic" = ":";
      };

      myconfig.programs.niri.outputs = lib.mkForce {
        "eDP-1" = {
          mode = {
            width = 3200;
            height = 2000;
            refresh = 120.0;
          };
        };
        "${niriKey lg}" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 144.0;
          };
          scale = 1.5;
          position = {
            x = 0;
            y = 0;
          };
          transform = {
            rotation = 90;
            flipped = false;
          };
        };
        "${niriKey asus}" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 240.0;
          };
          scale = 1.5;
          position = {
            x = 1440;
            y = 560;
          };
        };
      };
    };
  };
}
