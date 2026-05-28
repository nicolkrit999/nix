{ delib, ... }:
delib.module {
  name = "services.thermald";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { ... }: {
    services.thermald.enable = true;
  };
}
