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

      extensions = [
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; hash = "sha256-I3IsZqbm/AlZwVd376/N1tZumBZQ6nh5q16EJnIlBV0="; } # Proton Pass
        { id = "nlipoenfbbikpbjkfpfillcgkoblgpmj"; hash = "sha256-KxcUkvIkkuh3s4hPy7asTucfP9znwtd8hF2WFQjCutk="; } # Awesome Screen Recorder & Screenshot
        { id = "chphlpgkkbolifaimnlloiipkdnihall"; hash = "sha256-LkQLIahNewg6u+1AM85s0Ln0XsPNdfyVgGS0YqTkPBc="; } # OneTab
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; hash = "sha256-SKl2vE7oRj1+6aJXZc7IaaK557/5YZUGG+CJVCv+iXY="; } # Privacy Badger
        { id = "dphilobhebphkdjbpfohgikllaljmgbn"; hash = "sha256-IgmQYXUjBM0iONHXqTgcvIXihN2ZrXWCZsQZZg1xPxk="; } # SimpleLogin
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; hash = "sha256-nE5FE3Eo1jG8sT1KYjVl8JRbmAiyhN8IZObHsAIb0wY="; } # SponsorBlock
        { id = "lnaahdmijnjnmgaalacdgakieangpjgp"; hash = "sha256-xxdOTvjv9gaB1rS0bMsmrudydOGdTDtt73Ri+zRCpNQ="; } # Screenshot YouTube Video
        { id = "cdglnehniifkbagbbombnjghhcihifij"; hash = "sha256-weiUUUiZeeIlz/k/d9VDSKNwcQtmAahwSIHt7Frwh7E="; } # Kagi Search
        { id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; hash = "sha256-BnnCPisSxlhTSoQQeZg06Re8MhgwztRKmET9D93ghiw="; } # Kagi Summarizer
        { id = "ljipkdpcjbmhkdjjmbbaggebcednbbme"; hash = "sha256-wVSUhC4c24i4vpqeq1nZaeKtn32rn3+jorcC3WIaXJM="; } # Behind the Overlay
      ];

      extraPolicies = {
        BookmarkBarEnabled = false;

        # Homepage + new-tab — replaces the "New Tab Override" extension
        HomepageLocation = "https://kagi.com";
        HomepageIsNewTabPage = false;
        ShowHomeButton = true;
        NewTabPageLocation = "https://kagi.com";

        # Pin the six requested extensions. Left-to-right order is NOT
        # enforceable by policy (Chromium stores toolbar order in profile
        # Local State, not managed policies). Drag once after first launch;
        # desired order: Privacy Badger → OneTab → Behind the Overlay →
        # Kagi Summarizer → Proton Pass → SimpleLogin.
        ExtensionSettings = {
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp".toolbar_pin = "force_pinned"; # Privacy Badger
          "chphlpgkkbolifaimnlloiipkdnihall".toolbar_pin = "force_pinned"; # OneTab
          "ljipkdpcjbmhkdjjmbbaggebcednbbme".toolbar_pin = "force_pinned"; # Behind the Overlay
          "dpaefegpjhgeplnkomgbcmmlffkijbgp".toolbar_pin = "force_pinned"; # Kagi Summarizer
          "ghmbeldphafepmbegfdlkpapadhbakde".toolbar_pin = "force_pinned"; # Proton Pass
          "dphilobhebphkdjbpfohgikllaljmgbn".toolbar_pin = "force_pinned"; # SimpleLogin
        };
      };

      preferences = {
        browser.show_home_button = true;
        bookmark_bar.show_on_all_tabs = false;
        # helium.browser.layout = ?; # TODO: see memory — int enum for classic/compact/vertical, mapping unresolved
      };
    };
  };
}
