{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.mods = [
      "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
    ];
  };
}
