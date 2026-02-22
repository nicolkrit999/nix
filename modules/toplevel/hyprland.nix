{ delib
, ...
}:
delib.module {
  # TODO: probably can be renamed to "programs.hyprland" so that it's not enabled at all if the user does not want it
  name = "hyprland";
  options.hyprland = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
    };
}
