{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  tgt = inputs.tgt.packages.${system}.default;
in
delib.module {
  name = "programs.tgt";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ tgt ];
  };

  home.ifEnabled = { ... }: {
    home.activation.createTgtDir = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.tgt"
    '';
  };
}
