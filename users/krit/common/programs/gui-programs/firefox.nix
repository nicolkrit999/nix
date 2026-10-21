{ delib
, pkgs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.firefox";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled = { myconfig, ... }: {
    programs.firefox = {
      enable = true;
      profileName = lib.mkDefault myconfig.constants.user;
    };
  };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      homeDir = "${if moduleSystem == "darwin" then "/Users" else "/home"}/${myconfig.constants.user}";
      addons = pkgs.firefox-addons;
      profile = myconfig.programs.firefox.profileName;
    in
    {
      catppuccin.firefox = {
        enable = myconfig.constants.theme.catppuccin;
        flavor = myconfig.constants.theme.catppuccinFlavor;
        accent = myconfig.constants.theme.catppuccinAccent;
      };

      programs.firefox = {
        profiles.${profile} = {
          search = {
            force = true;
            default = "kagi";
            privateDefault = "kagi";
            order = [
              "kagi"
              "google"
              "ddg"
            ];
            engines = {
              kagi = {
                name = "kagi";
                urls = [
                  {
                    template = "https://kagi.com/search?q={searchTerms}";
                  }
                ];
                icon = "https://kagi.com/favicon.ico";
              };
              bing.metaData.hidden = true;
            };
          };

          # Attribute names come from https://nur.nix-community.org/repos/rycee/ (name without version)
          extensions = {
            force = true;
            packages = with addons; [
              ublock-origin # Popular ad and tracker blocker
              proton-pass # Proton Pass password manager integration
              firefox-color # Custom Firefox themes and color schemes. Needed for catppuccin
              sponsorblock # Skips sponsored segments in videos on platforms like YouTube
              gesturefy # Mouse gesture navigation for enhanced browsing
              privacy-badger # Tracker blocking extension by EFF
              screenshot-capture-annotate # Screenshot capturing and annotation tool (awesome screenshot)
              multi-account-containers # Isolates browsing activities into separate containers
              behind-the-overlay-revival # Bypass popup overlays on websites
              onetab # Save memory by converting tabs into a list
              simplelogin # Proton Mail's email alias manager
              kagi-search # Kagi search engine integration for private browsing
              new-tab-override # Customize the new tab page
              youtube-screenshot-button
            ];
          };

          settings = {
            "browser.startup.homepage" = "https://kagi.com/";
            "browser.startup.page" = 1;

            "browser.disableResetPrompt" = true;
            "browser.download.panel.shown" = true;
            "browser.rights.3.shown" = true;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.defaultBrowserCheckCount" = 1;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.uitour.enabled" = false;
            "startup.homepage_override_url" = "";
            "trailhead.firstrun.didSeeAboutWelcome" = true;
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.bookmarks.addedImportButton" = true;

            "network.trr.mode" = 2;
            "network.trr.uri" = "https://dns.quad9.net/dns-query";

            "extensions.autoDisableScopes" = 0;

            "browser.download.useDownloadDir" = true;
            "browser.download.folderList" = 2;
            "browser.download.dir" = "${homeDir}/Downloads";
            "browser.download.lastDir" = "${homeDir}/Downloads";

            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
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
            ]
              (_: 1);

            "app.shield.optoutstudies.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.updatePing.enabled" = false;

            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;
            "media.gmp-widevinecdm.visible" = true;

            "accessibility.typeaheadfind.enablesound" = false;

            "identity.fxaccounts.enabled" = false;

            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;
            "extensions.formautofill.addresses.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;

            "privacy.trackingprotection.enabled" = true;
            "dom.security.https_only_mode" = true;

            "browser.tabs.inTitlebar" = 0;

            "sidebar.verticalTabs" = true;
            "sidebar.revamp" = true;
            "sidebar.main.tools" = "history,bookmarks";

            "media.videocontrols.picture-in-picture.enabled" = true;
            "browser.uiCustomization.state" = builtins.toJSON {
              placements = {

                # Hide aggressive extensions that want to be pinned
                # Go to "about:support" --> adds-on. Search the name and user underscore instead of dot and keep lowercase
                # Additionally add to the "seen" list below to avoid re-adding them
                unified-extensions-area = [
                  "sponsorblocker_ajay_app-browser-action" # SponsorBlock
                  "newtaboverride_agenedia_com-browser-action" # New Tab Override
                ];

                widget-overflow-fixed-list = [ ];
                nav-bar = [
                  "back-button"
                  "forward-button"
                  "vertical-spacer" # Spacer
                  "home-button" # Home button
                  "stop-reload-button"
                  "urlbar-container" # Address bar
                  "downloads-button"
                  "_testpilot-containers-browser-action" # Multi Account Containers
                  "reset-pbm-toolbar-button" # Reset private browsing session (only visible in private mode)
                  "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action" # Behind the Overlay
                  "search_kagi_com-browser-action" # Kagi Search
                  "78272b6fa58f4a1abaac99321d503a20_proton_me-browser-action" # Proton Pass
                  "addon_simplelogin-browser-action" # SimpleLogin
                  "jid1-mnnxcxisbpnsxq_jetpack-browser-action" # Privacy Badger

                  "unified-extensions-button"
                ];
                toolbar-menubar = [ "menubar-items" ];
                TabsToolbar = [ ];
                vertical-tabs = [ "tabbrowser-tabs" ];
                PersonalToolbar = [ "personal-bookmarks" ];
              };
              seen = [
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
              currentVersion = 23;
              newElementCount = 10;
            };
          };
        };
      };
    };
}
