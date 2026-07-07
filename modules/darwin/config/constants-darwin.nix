{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      hostname = strOption "nixdarwin-host";
      user = strOption "nixdarwin";
      uid = intOption 1000;

      # State versions
      darwinStateVersion = intOption 4;
      homeStateVersion = noDefault (strOption null);

      browser = strOption "firefox";
      fileManager = strOption "nnn";
    };
}
