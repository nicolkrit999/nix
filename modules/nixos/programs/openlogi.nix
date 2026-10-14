{ delib, inputs, ... }:
delib.module {
  name = "programs.openlogi";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.openlogi.nixosModules.default ];
  };

  nixos.ifEnabled = { myconfig, ... }: {
    assertions = [{
      assertion = !(myconfig.krit.services.logitech.enable or false);
      message = "programs.openlogi and krit.services.logitech (logiops/solaar) both claim HID++ devices; enable only one";
    }];
    programs.openlogi = {
      enable = true;
      launchAtLogin = true;
    };
  };
}
