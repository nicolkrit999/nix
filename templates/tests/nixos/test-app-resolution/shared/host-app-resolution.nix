{ delib, ... }:
delib.host {
  name = "app-resolution";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = {
      user = "krit";
      hostname = "app-resolution-test";
      homeStateVersion = "25.11";
      terminal.name = "kitty";
      browser = "chromium";
      editor = "vim";
      fileManager = "yazi";
    };
  };
}
