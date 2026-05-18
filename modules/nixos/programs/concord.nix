{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  concord = inputs.concord.packages.${system}.default.overrideAttrs (old: {
    cargoExtraArgs = (old.cargoExtraArgs or "--locked") + " --features voice-playback";
  });
in
delib.module {
  # Discord tui
  name = "programs.concord";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ concord ];
  };
}
