{ delib, inputs, ... }:
delib.module {
  name = "programs.openlogi";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.openlogi.nixosModules.default ];
  };

  nixos.ifEnabled = { ... }: {
    programs.openlogi = {
      enable = true;
      launchAtLogin = true;
    };
  };
}
