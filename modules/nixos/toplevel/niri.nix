{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.niri";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };
  };
}
