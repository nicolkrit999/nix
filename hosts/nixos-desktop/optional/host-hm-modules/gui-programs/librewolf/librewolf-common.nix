{ pkgs, lib, inputs, vars, ... }:
let
  addons = pkgs.callPackage inputs.firefox-addons { };

  # 1. SEARCH ENGINES
  searchConfig = {
    force = true;
    default = "kagi";
    privateDefault = "kagi";
    order = [ "kagi" "ddg" "google" "perplexity" ];
    engines = {
      "kagi" = {
        urls = [{ template = "https://kagi.com/search?q={searchTerms}"; }];
        icon = "https://kagi.com/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@k" ];
      };
      "perplexity" = {
        urls =
          [{ template = "https://www.perplexity.ai/search?q={searchTerms}"; }];
        icon = "https://www.perplexity.ai/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@p" ];
      };
      # Visible search engines
      "google".metaData.hidden = false;
      "duckduckgo".metaData.hidden = false;

      # hidden search engines
      "bing".metaData.hidden = true;
      "ebay".metaData.hidden = true;
      "wikipedia".metaData.hidden = true;
      "wikipedia (en)".metaData.hidden = true;
      "metager".metaData.hidden = true;
      "mojeek".metaData.hidden = true;
      "wearx belgium".metaData.hidden = true;
      "startpage".metaData.hidden = true;
    };
  };

  # 2. UI LAYOUT (Toolbar Pinning)
  toolbarSettings = {
    "browser.uiCustomization.state" = builtins.toJSON {
      currentVersion = 23;
      newElementCount = 10;
      placements = {
        widget-overflow-fixed-list = [ ];
        nav-bar = [
          "back-button"
          "forward-button"
          "vertical-spacer" # Spacer
          "home-button" # Home button
          "stop-reload-button"
          "urlbar-container" # Address bar
          "downloads-button"
          "search_kagi_com-browser-action" # Kagi Search
          "jid1-mnnxcxisbpnsxq_jetpack-browser-action" # Privacy Badger
          "78272b6fa58f4a1abaac99321d503a20_proton_me-browser-action" # Proton Pass
          "addon_simplelogin-browser-action" # SimpleLogin
          "unified-extensions-button"
        ];
        toolbar-menubar = [ "menubar-items" ]; # Menubar when pressing "alt"
        TabsToolbar = [ ]; # Empty because we use vertical tabs
        vertical-tabs =
          [ "tabbrowser-tabs" ]; # Render the tab list in vertical tabs
      };
      seen = [
        "save-to-pocket-button"
        "developer-button"
        "ublock0_raymondhill_net-browser-action"
        "_testpilot-containers-browser-action"
        "screenshot-button"
        # Extensions to hide from the toolbar
        "sponsorblocker_ajay_app-browser-action"
        "newtaboverride_agenedia_com-browser-action"
      ];
      dirtyAreaCache = [
        "nav-bar"
        "PersonalToolbar"
        "toolbar-menubar"
        "TabsToolbar"
        "widget-overflow-fixed-list"
        "vertical-tabs"
      ];
    };
  };

  commonSettings = toolbarSettings // {
    # UI & Behavior
    "browser.startup.homepage" = "https://kagi.com/";
    "browser.compactmode.show" = true;
    "browser.uidensity" = 0;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.tabs.insertRelatedAfterCurrent" =
      true; # Open links next to active tab
    "browser.ctrlTab.sortByRecentlyUsed" = true; # Cycle tabs in MRU order
    "browser.warnOnQuit" = false; # Disable Quit Warning
    "browser.tabs.warnOnClose" = false;
    "browser.tabs.warnOnCloseOther" =
      false; # Tough in the ui it seems to be still enabled it work
    "media.videocontrols.picture-in-picture.video-toggle.enabled" =
      true; # Enable PiP toggle
    "browser.display.document_color_use" = 0;
    "browser.display.use_system_colors" = true;

    # Dark/light mode
    "ui.systemUsesDarkTheme" = if vars.polarity == "dark" then 1 else 0;
    "browser.in-content.dark-mode" = vars.polarity == "dark";

    # Don't ask for download dir and force it to Downloads
    "browser.download.useDownloadDir" = true;
    "browser.download.folderList" = 2;
    "browser.download.dir" = "/home/${vars.user}/Downloads";
    "browser.download.lastDir" = "/home/${vars.user}/Downloads";

    # Telemetry & Bloat
    "extensions.pocket.enabled" = false;
    "identity.fxaccounts.enabled" = false; # No Sync
    "datareporting.policy.dataSubmissionEnabled" = false;
    "browser.disableResetPrompt" = true;
    "browser.download.panel.shown" = true;
    "browser.feeds.showFirstRunUI" = false;
    "browser.messaging-system.whatsNewPanel.enabled" = false;
    "browser.rights.3.shown" = true;
    "browser.shell.defaultBrowserCheckCount" = 1;
    "browser.startup.homepage_override.mstone" = "ignore";
    "browser.uitour.enabled" = false;
    "startup.homepage_override_url" = "";
    "trailhead.firstrun.didSeeAboutWelcome" = true;
    "browser.bookmarks.restore_default_bookmarks" = false;
    "browser.bookmarks.addedImportButton" = true;
    "app.shield.optoutstudies.enabled" = false;
    "browser.discovery.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.ping-centre.telemetry" = false;
    "datareporting.healthreport.service.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.sessions.current.clean" = true;
    "devtools.onboarding.telemetry.logged" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.hybridContent.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.prompted" = 2;
    "toolkit.telemetry.rejected" = true;
    "toolkit.telemetry.reportingpolicy.firstRun" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.unifiedIsOptIn" = false;
    "toolkit.telemetry.updatePing.enabled" = false;

    # Disable crappy home activity stream page
    # hides the default promoted/suggested tiles on Firefox's new-tab screen from several major websites.
    "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
    "browser.newtabpage.activity-stream.showSearch" = false;
    "browser.newtabpage.activity-stream.feeds.snippets" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" =
      false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.system.showSponsored" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" =
      false;

    # Disable specific blocked new tab page tiles
    "browser.newtabpage.blocked" = lib.genAttrs [
      # Youtube
      "26UbzFJ7qT9/4DhodHKA1Q=="
      # Facebook
      "4gPpjkxgZzXPVtuEoAL9Ig=="
      # Wikipedia
      "eV8/WsSLxHadrTL1gAxhug=="
      # Reddit
      "gLv0ja2RYVgxKdp0I5qwvA=="
      # Amazon
      "K00ILysCaEq8+bEqV/3nuw=="
      # Twitter
      "T9nJot5PurhJSy8n038xGA=="
    ] (_: 1);

    # Disable "save password" prompt
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;

    # Remove close button
    "browser.tabs.inTitlebar" = 0;

    # Vertical tabs
    "sidebar.verticalTabs" = true;
    "sidebar.revamp" = true;
  };

in {
  # Disable Browserpass (i use proton pass)
  programs.browserpass.enable = false;

  # Launcher for privacy profile
  xdg.desktopEntries."librewolf-privacy" = {
    name = "LibreWolf Privacy";
    genericName = "Web Browser";
    exec = "librewolf -P Privacy --no-remote";
    icon = "librewolf";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    comment = "Launch LibreWolf in Hardened Privacy Mode";
  };

  programs.librewolf = {
    enable = true;

    # Dummy package to allow hm to install librewolf using home-packages.nix but applying these custom configs
    package = pkgs.lib.makeOverridable
      (_args: pkgs.runCommand "librewolf-dummy" { } "mkdir $out") { };

    # Global Policies
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;

      ExtensionSettings = {
        # Allow installing other extensions manually
        "*".installation_mode = "allowed";
      };
      Cookies = {
        # Allow certain cookies to persist even in privacy mode
        # Everything to the right of the domain is allowed
        # If sommething comes before the domain then it must be added
        Allow = [
          # Kagi
          "https://kagi.com"
          "https://translate.kagi.com/"
          "https://news.kagi.com/"
          "https://kagi.com/summarizer/"

          # PROTON
          "https://proton.me"
          "https://account.proton.me"
          "https://api.proton.me"
          "https://auth.proton.me"
          "https://docs.proton.me"
          "https://wallet.proton.me"
          "https://mail.proton.me"
          "https://calendar.proton.me"
          "https://drive.proton.me"
          "https://pass.proton.me"
          "https://lumo.proton.me"

          # PROTON LEGACY (Required for redirects)
          "https://protonmail.com"
          "https://account.protonmail.com"
          "https://protonmail.ch"

          # SIMPLELOGIN
          "https://simplelogin.io"
          "https://app.simplelogin.io"
          "https://simplelogin.com"
          "https://auth.simplelogin.com"

          # Cloudflare
          "https://cloudflareaccess.com"
          "https://cloudflare.com"

          # Others
          "https://nicolkrit.ch"
        ];
      };
    };

    # Import Profiles
    profiles = {
      default = (import ./librewolf-profile-default.nix {
        inherit pkgs addons searchConfig commonSettings vars inputs;
      });

      privacy = (import ./librewolf-profile-privacy.nix {
        inherit pkgs addons searchConfig commonSettings vars inputs;
      });
    };
  };
}
