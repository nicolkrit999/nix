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
    # Packages specific to this machine
    ./optional/host-packages/default.nix

  ];

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🌍 LOCALE
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  i18n.defaultLocale = "en_US.UTF-8";

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  users.users.${vars.user} = {
    isNormalUser = true;
    description = "Primary user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "video"
      "audio"
    ];
  };
}
