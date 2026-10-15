{ delib
, ...
}:
delib.module {
  name = "home";

  home.always =
    { myconfig, ... }:
    {
      home = {
        stateVersion = myconfig.constants.homeStateVersion;
        sessionPath = [ "$HOME/.local/bin" ];
      };

      programs.home-manager.enable = true;
    };
}
