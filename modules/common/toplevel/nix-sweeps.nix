{ delib, pkgs, inputs, ... }:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sharedIfEnabledBody = {
    environment.systemPackages = [ pkgs-unstable.nix-sweep ];
  };
in
delib.module {
  name = "nix-sweeps";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      gcd = strOption "30d";
      gcn = strOption "3";
    };

  nixos.ifEnabled = { ... }: sharedIfEnabledBody;

  darwin.ifEnabled = { ... }: sharedIfEnabledBody;

  home.ifEnabled =
    { cfg, ... }:
    {
      xdg.configFile."nix-sweep/presets.toml".text = ''
        [default]
        keep-min = ${cfg.gcn}
        remove-older = "${cfg.gcd}"
        interactive = false
        gc = true

        [ask]
        keep-min = ${cfg.gcn}
        remove-older = "${cfg.gcd}"
        interactive = true
        gc = true
      '';
    };
}
