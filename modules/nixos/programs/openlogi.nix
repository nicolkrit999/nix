{ delib, inputs, lib, pkgs, ... }:
let
  # TEMP: zstd buildInput; remove when upstream lists zstd.
  openlogiUpstream = inputs.openlogi.packages.${pkgs.stdenv.hostPlatform.system}.openlogi;
  openlogiPackage =
    if lib.any (p: (p.pname or "") == "zstd") (openlogiUpstream.buildInputs or [ ]) then openlogiUpstream
    else
      openlogiUpstream.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zstd ];
      });
in
delib.module {
  name = "programs.openlogi";
  options = delib.singleEnableOption false;

  nixos.always = {
    disabledModules = [ "programs/openlogi.nix" ];
    imports = [ inputs.openlogi.nixosModules.default ];
  };

  nixos.ifEnabled = {
    programs.openlogi = {
      enable = true;
      package = openlogiPackage;
      launchAtLogin = true;
    };
  };
}
