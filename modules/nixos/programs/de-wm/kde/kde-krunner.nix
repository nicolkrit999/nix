# Configure krunner using the community "plasma-manager" flake
{ delib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      programs.plasma.krunner = {
        position = "top";
        activateWhenTypingOnDesktop = true;
        historyBehavior = "enableSuggestions";
      };
    };
}
