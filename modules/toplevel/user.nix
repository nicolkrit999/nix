{ delib, pkgs, ... }:
delib.module {
  name = "system.user";

  nixos.always =
    { nixos, ... }:
    let
      currentShell = nixos.constants.shell or "zsh";

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
        users.${nixos.constants.user} = {
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
