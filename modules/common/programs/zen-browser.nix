{ delib
, inputs
, ...
}:
delib.module {
  name = "programs.zen.browser";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [ inputs.zen-browser.homeModules.beta ];
  };

  home.ifEnabled = { ... }: {
    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };
  };

  darwin.ifEnabled = { ... }: {
    programs.zen-browser.darwinDefaultsId = "app.zen-browser.zen";
  };
}
