{ delib, ... }:
delib.module {
  name = "krit.programs.zen-browser";

  home.ifEnabled = {
    programs.zen-browser.profiles.default.search = {
      force = true;
      default = "ddg";
      engines = {
        "ddg".metaData.alias = "@d";
        "google".metaData.alias = "@g";
        "kagi" = {
          urls = [{ template = "https://kagi.com/search?q={searchTerms}"; }];
          updateInterval = 24 * 60 * 60 * 1000;
          definedAliases = [ "@k" ];
        };
      };
    };
  };
}
