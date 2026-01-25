{
  config,
  pkgs,
  lib,
  vars,
  ...
}:
{
  # home.nix and host-modules are imported from flake.nix
  imports = [

    # Common  modules
    # Import here if you have a personal common modules folders
    #../../common

  ]
  ++ (lib.optional (builtins.pathExists ./optional/default.nix) ./optional/default.nix);

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🌍 LOCALE
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  i18n.defaultLocale = "en_US.UTF-8";

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  users.users.${vars.user} = {
    isNormalUser = true;
    description = "${vars.user}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "video"
      "audio"
    ];
  };

  environment.systemPackages = with pkgs; [ ];
}
