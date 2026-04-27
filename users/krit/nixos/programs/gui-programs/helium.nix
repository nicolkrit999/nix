{ delib, inputs, ... }:
let
  # CWS extension IDs. Installed via ExtensionInstallForcelist policy so
  # Chromium fetches them from the Web Store itself — that path persists
  # install state in the profile, so chrome.runtime.onInstalled fires once
  # on first launch instead of every launch (which is what --load-extension
  # caused, producing welcome-tab spam on every startup).
  extensionIds = [
    "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
    "nlipoenfbbikpbjkfpfillcgkoblgpmj" # Awesome Screen Recorder & Screenshot
    "chphlpgkkbolifaimnlloiipkdnihall" # OneTab
    "dphilobhebphkdjbpfohgikllaljmgbn" # SimpleLogin
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "lnaahdmijnjnmgaalacdgakieangpjgp" # Screenshot YouTube Video
    "cdglnehniifkbagbbombnjghhcihifij" # Kagi Search
    "dpaefegpjhgeplnkomgbcmmlffkijbgp" # Kagi Summarizer
    "ljipkdpcjbmhkdjjmbbaggebcednbbme" # Behind the Overlay
  ];

  cwsUpdateUrl = "https://clients2.google.com/service/update2/crx";
in
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

        HomepageLocation = "https://kagi.com";
        HomepageIsNewTabPage = false;
        ShowHomeButton = true;
        NewTabPageLocation = "https://kagi.com";

        ExtensionInstallForcelist = map (id: "${id};${cwsUpdateUrl}") extensionIds;

        # Pin the requested extensions. Left-to-right order is NOT
        # enforceable by policy (Chromium stores toolbar order in profile
        # Local State, not managed policies). Drag once after first launch;
        # desired order: OneTab → Behind the Overlay → Kagi Summarizer →
        # Proton Pass → SimpleLogin.
        ExtensionSettings = {
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
      };
    };
  };
}
