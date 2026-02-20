{
  delib,
  lib,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:

    {
      programs.plasma.krunner = {
        position = "top";
        activateWhenTypingOnDesktop = true;
        historyBehavior = "enableSuggestions";
      };
    };
}
