{ delib, ... }:
delib.host {
  name = "cc-bare";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
    programs.claude-code.enable = true;
  };
}
