{ delib, pkgs, pkgs-unstable, ... }:
delib.module {
  name = "user";

  nixos.always =
    { myconfig, ... }:
    let
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
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs-unstable.nixos-rebuild}/bin/nixos-rebuild";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
