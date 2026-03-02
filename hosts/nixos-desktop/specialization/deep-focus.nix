{
  delib,
  lib,
  config,
  ...
}:
# FIXME: Doesn´t load infinite splash screen loader
let
  myUserName = "krit";

  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    nixpkgs.config.allowUnfree = true;
    specialisation.deep-focus.configuration = {
      system.nixos.tags = [ "deep-focus" ];
      # Take default chosen apps but change their workspace
      myconfig.programs.hyprland.execOnce = lib.mkForce (
        let
          c = config.myconfig.constants;
          smartLaunch =
            app: if builtins.elem app termApps then "${c.terminal} --class ${app} -e ${app}" else app;
        in
        [
          "[workspace 1 silent] ${c.browser}"
          "[workspace 2 silent] ${smartLaunch c.editor}"
          "[workspace 3 silent] ${smartLaunch c.fileManager}"
          "[workspace 4 silent] ${c.terminal}"
        ]
      );

      myconfig.programs.hyprland.windowRules = lib.mkAfter (
        let
          c = config.myconfig.constants;
        in
        [
          "workspace 1, class:^(${c.browser})$"
          "workspace 2, class:^(${c.editor})$"
          "workspace 3, class:^(${c.fileManager})$"
          "workspace 4, class:^(${c.terminal})$"
        ]
      );

      # ---------------------------------------------------------
      # 3. 🤫 DO NOT DISTURB (All Desktop Environments)
      # ---------------------------------------------------------
      home-manager.users.${myUserName} =
        { pkgs, lib, ... }:
        {
          home.activation.enableDND = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            # 1. Silence SwayNC (Hyprland/Niri)
            ${pkgs.swaynotificationcenter}/bin/swaync-client -d -b || true

            # 2. Silence GNOME
            ${pkgs.glib}/bin/gsettings set org.gnome.desktop.notifications show-banners false || true

            # 3. Silence KDE Plasma
            ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasmanotifyrc --group Notifications --key DoNotDisturb true || true
          '';
        };
    };
  };
}
