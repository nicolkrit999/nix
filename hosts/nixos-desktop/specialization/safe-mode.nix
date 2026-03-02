{ delib, lib, pkgs, ... }:
delib.host {
  name = "nixos-desktop";

  nixos = {
    specialisation.safemode.configuration = {
      system.nixos.tags = [ "safemode-tty" ];

      # ---------------------------------------------------------
      # 1. 🛑 KILL ALL COMPLEXITY & GUI AUTOSTART
      # ---------------------------------------------------------
      # Disable SDDM entirely. This forces the system to boot to a
      # secure TTY text login.
      services.displayManager.sddm.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;

      # Kill all complex Wayland environments
      myconfig.programs.hyprland.enable = lib.mkForce false;
      myconfig.programs.niri.enable = lib.mkForce false;
      myconfig.programs.cosmic.enable = lib.mkForce false;
      myconfig.programs.kde.enable = lib.mkForce false;
      myconfig.programs.gnome.enable = lib.mkForce false;

      # ---------------------------------------------------------
      # 2. 🛡️ XFCE ON DEMAND
      # ---------------------------------------------------------
      # type `startxfce4` in the TTY after logging in to start a simple XFCE session.
      services.xserver.desktopManager.xfce.enable = lib.mkForce true;
      services.xserver.displayManager.startx.enable = lib.mkForce true;

      # ---------------------------------------------------------
      # 3. 🧹 DISABLE THEMES & CUSTOM SHELLS
      # ---------------------------------------------------------
      myconfig.stylix.enable = lib.mkForce false;
      myconfig.constants.theme.catppuccin = lib.mkForce false;
      myconfig.programs.caelestia.enable = lib.mkForce false;
      myconfig.programs.noctalia.enable = lib.mkForce false;

      # Force standard Bash to bypass broken Zsh/Fish plugins
      myconfig.constants.shell = lib.mkForce "bash";
      myconfig.constants.terminal = lib.mkForce "xterm";
      myconfig.constants.editor = lib.mkForce "nano";

      # ---------------------------------------------------------
      # 4. 🧰 SURVIVAL TOOLKIT
      # ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        # CLI File Management
        mc          # Midnight Commander (Dual-pane visual CLI file manager - a lifesaver)
        ncdu        # Visual disk usage analyzer (in case your disk is 100% full)

        # Editors
        nano
        vim

        # System & Process Monitors
        htop
        killall

        # Disk & Filesystem
        parted
        btrfs-progs # Btrfs filesystem tools (to fix broken Btrfs filesystems)

        # Network Rescue
        networkmanager # Ensures nmtui (Network Manager Text UI) is available for WiFi
        curl
        wget

        # Version Control (to fix/pull from your repo)
        git

        # XFCE terminal (just in case you launch the GUI)
        xfce.xfce4-terminal
      ];
    };
  };
}
