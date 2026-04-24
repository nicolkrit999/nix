{ delib, inputs, ... }:
delib.module {
  name = "krit.programs.helium";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [ inputs.helium.nixosModules.helium ];
  };

  home.always = { ... }: {
    imports = [ inputs.helium.homeModules.helium ];
  };

  home.ifEnabled = { ... }: {
    programs.helium = {
      enable = true;
      defaultBrowser = false;

      extensions = [ ];

      extraPolicies = {
        BookmarkBarEnabled = false;
      };

      preferences = {
        browser.show_home_button = true;
        bookmark_bar.show_on_all_tabs = false;
        # helium.browser.layout = ?; # Unknown: likely controls UI layout mode (tab bar position/style)
      };
    };
  };
}
