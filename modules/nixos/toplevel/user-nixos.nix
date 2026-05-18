{ delib, inputs, pkgs, ... }:
delib.module {
  name = "user";

  nixos.always =
    { myconfig, ... }:
    let
      pkgs-unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
      currentShell = myconfig.constants.shell or "zsh";

      shellPkg =
        if currentShell == "fish" then
          pkgs.fish
        else if currentShell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      # Bash is enabled by default thus not needed here
      programs.zsh.enable = currentShell == "zsh";
      programs.fish.enable = currentShell == "fish";

      users = {
        defaultUserShell = shellPkg;
        users.${myconfig.constants.user} = {
          isNormalUser = true;
          shell = shellPkg;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
        };
      };

      security.sudo.extraRules = [
        {
          users = [ myconfig.constants.user ];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "${pkgs-unstable.nixos-rebuild}/bin/nixos-rebuild";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "/nix/store/*-nixos-rebuild*/bin/nixos-rebuild";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "/nix/store/*/bin/switch-to-configuration";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/switch-to-configuration";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "${pkgs.nh}/bin/nh";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/nh";
              options = [ "SETENV" "NOPASSWD" ];
            }
            {
              command = "/nix/store/*-nh-*/bin/nh";
              options = [ "SETENV" "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
