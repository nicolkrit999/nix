{ delib
, pkgs
, ...
}:
delib.module {
  # TODO: probably can be renamed to "programs.niri" so that it's not enabled at all if the user does not want it
  name = "niri";
  options.niri = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };
    };
}
