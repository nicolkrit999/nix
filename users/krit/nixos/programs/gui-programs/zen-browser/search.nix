{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.search = {
      force = true;
      default = "kagi";
      engines = {
        "kagi" = {
          urls = [{ template = "https://kagi.com/search?q={searchTerms}"; }];
          updateInterval = 24 * 60 * 60 * 1000;
          definedAliases = [ "@k" ];
        };
      };
    };
  };
}
