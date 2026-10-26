{ delib
, lib
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

  rainWorld = {
    url = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
    sha256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";
  };

  hyprDesc = m: "desc:${m.make} ${m.model} ${m.serial}";

  niriKey = m: "${m.make} ${m.model} ${m.serial}";

  silent = workspace: "${workspace} silent";
  workspaceRules = workspace: classes: map (class: { match.class = class; inherit workspace; }) classes;
  scratchRule = class: {
    match.class = "^(${class})$";
    float = true;
    center = true;
    size = "80% 80%";
    workspace = "special:magic";
  };
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

      myconfig = {
        constants.wallpapers = lib.mkForce [
          {
            targetMonitor = "eDP-1";
            wallpaperURL = rainWorld.url;
            wallpaperSHA256 = rainWorld.sha256;
          }
          {
            targetMonitor = hyprDesc lg;
            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
            wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
          }
          {
            targetMonitor = hyprDesc asus;
            wallpaperURL = rainWorld.url;
            wallpaperSHA256 = rainWorld.sha256;
          }
        ];

        programs = {
          mango.enable = lib.mkForce false;
          hyprland = {
            monitors = lib.mkForce [
              { output = "eDP-1"; mode = "3200x2000@120"; position = "4000x560"; scale = 1.6; }
              { output = hyprDesc lg; mode = "3840x2160@144"; position = "0x0"; scale = 1.5; transform = 1; bitdepth = 10; }
              { output = hyprDesc asus; mode = "3840x2160@240"; position = "1440x560"; scale = 1.5; bitdepth = 10; }
            ];

            monitorWorkspaces = lib.mkForce [
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

            windowRules = lib.mkForce (
              workspaceRules "2" [ "^(nvim)$" ]
              ++ workspaceRules (silent "2") [
                "^(code)$"
                "^(nvim-editor)$"
                "^(org.kde.kate)$"
                "^(jetbrains-pycharm-ce)$"
                "^(jetbrains-Clion)$"
                "^(jetbrains-idea)$"
              ]
              ++ workspaceRules (silent "3") [
                "^(org.kde.dolphin)$"
                "^(thunar)$"
                "^(yazi)$"
                "^(ranger)$"
                "^(org.gnome.Nautilus)$"
                "^(nemo)$"
              ]
              ++ workspaceRules (silent "7") [ "^(winboat)$" ]
              ++ workspaceRules (silent "10") [ "^(Actual)$" ]
              ++ workspaceRules (silent "6") [
                "^(org.jellyfin.JellyfinDesktop)$"
                "^(brave-browser)$"
                "^(brave-.*\\..*)$"
                "(?i)spotify"
                "^(sidra)$"
                "^(de\\.haeckerfelix\\.Shortwave)$"
              ]
              ++ workspaceRules (silent "8") [
                "^(kitty)$"
                "^(alacritty)$"
                "^(foot)$"
                "^(xfce4-terminal)$"
                "^(com.system76.CosmicTerm)$"
                "^(org.kde.konsole)$"
                "^(gnome-terminal)$"
                "^(XTerm)$"
              ]
              ++ workspaceRules (silent "9") [
                "^(vesktop)$"
                "^(discord)$"
                "^(org.telegram.desktop)$"
                "^(whatsapp-electron)$"
                "^(com.rtosta.zapzap)$"
              ]
              ++ map scratchRule [
                "scratch-term"
                "scratch-fs"
                "scratch-browser"
              ]
              ++ [
                {
                  match.class = "^winboat-.*$";
                  workspace = "7";
                  suppress_event = "fullscreen maximize activate activatefocus";
                  no_initial_focus = true;
                  no_anim = true;
                  rounding = 0;
                  no_shadow = true;
                  no_blur = true;
                  opaque = true;
                }
              ]
            );

            execOnce = lib.mkForce [
              "hyprctl dispatch 'hl.dsp.focus({ workspace = \"1\" })'"
              "[workspace 1 silent] zen-beta"
              "[workspace 2 silent] kitty --class nvim -e nvim"
              "[workspace 3 silent] kitty --class yazi -e yazi"
              "[workspace 8 silent] kitty"
              "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
            ];
          };

          waybar-hyprland.waybarWorkspaceIcons = lib.mkForce {
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

          niri.outputs = lib.mkForce {
            "eDP-1" = {
              mode = {
                width = 3200;
                height = 2000;
                refresh = 120.0;
              };
              # match hyprland home-spec eDP-1 (scale 1.6 at 4000x560)
              scale = 1.6;
              position = {
                x = 4000;
                y = 560;
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
    };
  };
}
