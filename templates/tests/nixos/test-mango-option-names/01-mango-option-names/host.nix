{ delib, ... }:
delib.host {
  name = "mk-01-mango-option-names";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ../../test-nixos-wallpapers/shared/base-constants-static.nix;

    programs.hyprland.enable = false;
    programs.niri.enable = false;
    programs.gnome.enable = false;
    programs.kde.enable = false;
    programs.skwdWall.enable = false;

    programs.mango = {
      enable = true;
      monitors = [
        "name:^DP-1$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
        "name:^HDMI-A-1$,width:1920,height:1080,refresh:60,x:4000,y:560,scale:1,disable:1"
      ];
      windowRules = [
        "monitor:^DP-1$,app_id:^mango-startup-editor$"
        "is_floating:1,width:0.8,height:0.8,tags:0,app_id:^scratch-term$"
      ];
      windowRulesOnce = [ "monitor:^DP-1$,app_id:^zen-beta$" ];
    };

    programs.waybar-hyprland.enable = false;
    programs.waybar-niri.enable = false;
    programs.waybar-mango.enable = false;
    services.swaync.enable = false;
  };
}
