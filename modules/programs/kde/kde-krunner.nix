{
  delib,
  lib,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg, myconfig, ... }:

    {
      programs.plasma.krunner = {
        position = "top";
        activateWhenTypingOnDesktop = true;
        historyBehavior = "enableSuggestions";
      };
    };
}
