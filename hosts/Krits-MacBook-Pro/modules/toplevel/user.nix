{ delib, pkgs, ... }:
delib.module {
  name = "user";

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
}
