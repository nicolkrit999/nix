{ delib, pkgs, ... }:
delib.module {
  name = "system.user";

  myconfig.always =
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
    };
}
