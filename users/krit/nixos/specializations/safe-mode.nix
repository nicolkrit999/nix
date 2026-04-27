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
  name = "krit.specializations.safe-mode";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;

    specialisation.safemode.configuration = {
      system.nixos.tags = [ "safemode-tty" ];

      # ---------------------------------------------------------
      # 1. KILL ALL COMPLEXITY & GUI AUTOSTART
      # ---------------------------------------------------------
      services.displayManager.sddm.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;

      myconfig.programs.hyprland.enable = lib.mkForce false;
      myconfig.programs.niri.enable = lib.mkForce false;
      myconfig.programs.cosmic.enable = lib.mkForce false;
      myconfig.programs.kde.enable = lib.mkForce false;
      myconfig.programs.gnome.enable = lib.mkForce false;
      services.xserver.desktopManager.xfce.enable = lib.mkForce false;

      # ---------------------------------------------------------
      # 2. SAFE MODE GUI (IceWM)
      # ---------------------------------------------------------
      services.xserver.windowManager.icewm.enable = lib.mkForce true;
      services.xserver.displayManager.startx.enable = lib.mkForce true;

      # ---------------------------------------------------------
      # 3. DISABLE THEMES & CUSTOM SHELLS
      # ---------------------------------------------------------
      myconfig.stylix.enable = lib.mkForce false;
      myconfig.constants.theme.catppuccin = lib.mkForce false;
      myconfig.programs.caelestia.enable = lib.mkForce false;
      myconfig.programs.noctalia.enable = lib.mkForce false;

      # Feed Stylix dummy data to prevent evaluation errors
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      stylix.image = lib.mkForce (pkgs.writeText "dummy-image.png" "");

      home-manager.users.${myUserName} =
        { lib, pkgs, ... }:
        {
          options.stylix.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };

          config = {
            stylix.enable = lib.mkForce false;

            home.file.".xinitrc".text = ''
              #!/bin/sh
              # Auto-detect and enable all connected monitors at preferred resolution
              ${pkgs.xorg.xrandr}/bin/xrandr --auto || true

              # Launch IceWM
              exec ${pkgs.icewm}/bin/icewm-session
            '';

            home.file.".xinitrc".executable = true;
          };
        };

      # Force standard Bash to bypass broken Zsh/Fish plugins
      myconfig.constants.shell = lib.mkForce "bash";
      myconfig.constants.terminal.name = lib.mkForce "xterm";
      myconfig.constants.editor = lib.mkForce "nano";

      # ---------------------------------------------------------
      # 4. SURVIVAL TOOLKIT
      # ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        mc # Visual CLI file manager
        ncdu # Visual disk usage analyzer
        nano
        vim
        htop
        killall
        parted
        btrfs-progs # Btrfs tools (to fix broken Btrfs filesystems)
        networkmanager
        curl
        wget
        git
        xfce.xfce4-terminal
      ];
    };
  };
}
