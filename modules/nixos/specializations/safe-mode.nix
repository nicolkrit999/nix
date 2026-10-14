{ delib
, lib
, config
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
in
delib.module {
  name = "specializations.safe-mode";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.safemode.configuration = {
      system.nixos.tags = [ "safemode-tty" ];

      # ---------------------------------------------------------
      # 1. KILL DISPLAY MANAGERS, ENABLE SAFE MODE GUI (IceWM via startx)
      # ---------------------------------------------------------
      services = {
        displayManager.sddm.enable = lib.mkForce false;
        xserver = {
          enable = true;
          desktopManager.xfce.enable = lib.mkForce false;
          displayManager = {
            lightdm.enable = lib.mkForce false;
            startx.enable = lib.mkForce true;
          };
          windowManager.icewm.enable = lib.mkForce true;
        };
      };

      # ---------------------------------------------------------
      # 2. DISABLE THEMES & CUSTOM SHELLS
      # ---------------------------------------------------------
      myconfig = {
        stylix.enable = lib.mkForce false;
        constants = {
          theme.catppuccin = lib.mkForce false;
          # Force standard Bash to bypass broken Zsh/Fish plugins
          shell = lib.mkForce "bash";
          terminal.name = lib.mkForce "xterm";
          editor = lib.mkForce "nano";
        };
        programs = {
          caelestia.enable = lib.mkForce false;
          cosmic.enable = lib.mkForce false;
          fastfetch.enable = lib.mkForce false;
          gnome.enable = lib.mkForce false;
          hyprland.enable = lib.mkForce false;
          kde.enable = lib.mkForce false;
          mango.enable = lib.mkForce false;
          niri.enable = lib.mkForce false;
          noctalia.enable = lib.mkForce false;
        };
      };

      # Stylix is disabled but still evaluates: give it a scheme and an empty
      # placeholder file only to satisfy the required stylix.image option
      stylix = {
        base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        image = lib.mkForce (pkgs.writeText "dummy-image.png" "");
      };

      home-manager.users.${myUserName} =
        { lib, pkgs, ... }:
        {
          options.stylix.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };

          config = {
            stylix.enable = lib.mkForce false;

            home = {
              file.".xinitrc" = {
                executable = true;
                text = ''
                  #!/bin/sh
                  # Auto-detect and enable all connected monitors at preferred resolution
                  ${pkgs.xrandr}/bin/xrandr --auto || true

                  # Launch IceWM
                  exec ${pkgs.icewm}/bin/icewm-session
                '';
              };

              shellAliases.start-icewm = "startx";
            };
          };
        };

      # ---------------------------------------------------------
      # 3. SURVIVAL TOOLKIT
      # ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        # Disk and filesystem
        btrfs-progs
        ncdu
        parted

        # Editors
        nano
        vim

        # File management
        mc

        # Network and download
        curl
        networkmanager
        wget

        # Process and system
        htop
        killall

        # Terminal and VCS
        git
        xfce4-terminal
      ];
    };
  };
}
