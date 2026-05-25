{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  tgt = inputs.tgt.packages.${system}.default;
in
delib.module {
  # Telegram tui
  name = "programs.tgt";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ tgt ];
  };
}
