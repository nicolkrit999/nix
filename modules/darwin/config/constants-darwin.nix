{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      hostname = strOption "nixdarwin-host";
      user = strOption "nixdarwin";
      uid = noDefault (intOption null);

      # State versions
      darwinStateVersion = noDefault (intOption null);
      homeStateVersion = noDefault (strOption null);

      # Set to "" to opt a host out of the browser package
      # in home-packages-darwin.nix (e.g. a CI-only host with no browser use).
      browser = strOption "firefox";
      fileManager = strOption "nnn";
    };
}
