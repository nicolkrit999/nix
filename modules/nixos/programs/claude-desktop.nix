{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-desktop";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.overlays = [
      inputs.claude-desktop.overlays.default
      (final: prev: {
        claude-desktop = prev.claude-desktop.overrideAttrs (old: {
          buildInputs = old.buildInputs ++ [ final.pipewire ];
        });
      })
    ];
    environment.systemPackages = [ pkgs.claude-desktop-fhs ];
  };
}
