{ delib, ... }:
delib.module {
  name = "programs.nh";
  options.programs.nh = with delib; {
    enable = boolOption true;
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      programs.nh = {
        enable = true;
        clean.enable = true;
        # Keep generations from the last 30 days and at least 20 generations
        clean.extraArgs = "--keep-since 30d --keep 20";
        flake = "/home/${myconfig.constants.user}/nixOS";
      };
    };
}
