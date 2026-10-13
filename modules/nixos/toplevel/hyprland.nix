{ delib
, lib
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

    # file-capability wrapper would make the binary AT_SECURE (loader strips LD_*, breaks zapzap/flatpak); reason inferred from b1b0fffa, not confirmed
    security.wrappers.Hyprland.capabilities = lib.mkForce "";
  };
}
