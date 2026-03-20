{ delib, pkgs, ... }:
delib.module {
  name = "user";

  # ===========================================================================
  # DARWIN USER CONFIGURATION
  # ===========================================================================
  darwin.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) user shell uid;
      shellPkg =
        if shell == "fish" then
          pkgs.fish
        else if shell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      users.knownUsers = [ user ];
      users.users.${user} = {
        inherit uid;
        shell = shellPkg;
        home = "/Users/${user}";
      };

      environment.shells = [ shellPkg ];
    };

  # ===========================================================================
  # NIXOS USER CONFIGURATION
  # ===========================================================================
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
    };
}
