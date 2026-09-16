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

      # Set to "" to opt a host out of the forced browser-fallback package
      # in home-packages-darwin.nix (e.g. a CI-only host with no browser use).
      browser = strOption "firefox";
      fileManager = strOption "nnn";
    };
}
