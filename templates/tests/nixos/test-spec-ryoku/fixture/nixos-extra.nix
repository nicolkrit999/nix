{ config, inputs, ... }:
let
  user = config.myconfig.constants.user;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
  boot.loader.grub.enable = false;
  users.mutableUsers = false;
  users.users.${user} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };
  systemd.tmpfiles.rules = [ "d /home/${user}/.cache 0700 ${user} users -" ];
  home-manager.users.${user} = { lib, ... }: {
    options.catppuccin.eza.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    config.home.stateVersion = "25.11";
    config.programs = {
      kitty = {
        enable = true;
        settings.font_size = 11;
      };
      fish.enable = true;
      yazi = {
        enable = true;
        shellWrapperName = "y";
        settings.mgr.show_hidden = true;
      };
      eza.enable = true;
    };
  };
}
