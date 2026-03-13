{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-code";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

    environment.systemPackages = [ pkgs.claude-code ];
  };
}
