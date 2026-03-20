{ delib
, ...
}:
delib.module {
  name = "home";

  home.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) user;
      homeDir = "/Users/${user}";
    in
    {
      home = {
        username = user;
        homeDirectory = homeDir;
        stateVersion = myconfig.constants.homeStateVersion or "25.11";
        sessionPath = [ "$HOME/.local/bin" ];
      };

      programs.home-manager.enable = true;
    };
}
