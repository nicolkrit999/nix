{ delib, pkgs, ... }:
delib.module {
  name = "home";

  home.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) user;
    in
    {
      home = {
        username = user;
        homeDirectory = "/Users/${user}";
        sessionPath = [ "$HOME/.local/bin" ];
      };

      programs.home-manager.enable = true;
    };
}
