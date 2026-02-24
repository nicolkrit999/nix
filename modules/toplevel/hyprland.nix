{ delib
, ...
}:
delib.module {
  name = "programs.hyprland";
  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
}
