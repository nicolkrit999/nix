{ delib, pkgs, ... }:
delib.module {
  name = "services.localsend";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.programs.localsend = {
    enable = true;
    # Temporary workaround: remove when nixpkgs#585411 is in the locked unstable and #585072 is closed.
    package = pkgs.localsend.overrideAttrs (old: {
      runtimeDependencies = (old.runtimeDependencies or [ ]) ++ [ pkgs.zlib ];
    });
  };
}
