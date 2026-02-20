{
  delib,
  lib,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg, nixos, ... }:

    {
      programs.plasma.krunner = {
        position = "top";
        activateWhenTypingOnDesktop = true;
        historyBehavior = "enableSuggestions";
      };
    };
}
