{ delib, inputs, lib, pkgs, ... }:
let
  # TEMPORARY: cargo-setup-hook forces ZSTD_SYS_USE_PKG_CONFIG=1 (xtask zstd-sys in checkPhase); remove when upstream package.nix lists zstd.
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

  nixos.ifEnabled = { myconfig, ... }: {
    assertions = [{
      assertion = !(myconfig.krit.services.logitech.enable or false);
      message = "programs.openlogi and krit.services.logitech (logiops/solaar) both claim HID++ devices; enable only one";
    }];
    programs.openlogi = {
      enable = true;
      package = openlogiPackage;
      launchAtLogin = true;
    };
  };
}
