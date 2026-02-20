{
  delib,
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
delib.module {
  name = "krit.programs.firefox";
  options.krit.programs.firefox = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:
    let
      # Allow to install "unfree" addons by rebuilding them locally
      buildFirefoxXpiAddon = lib.makeOverridable (
        {
          stdenv ? pkgs.stdenv,
          fetchurl,
          pname,
          version,
          addonId,
          url,
          sha256,
          meta,
          ...
        }:
        stdenv.mkDerivation {
          name = "${pname}-${version}";
          inherit meta;
          src = fetchurl { inherit url sha256; };
          preferLocalBuild = true;
          allowSubstitutes = true;
          passthru = { inherit addonId; };
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            install -v -m644 "$src" "$dst/${addonId}.xpi"
          '';
        }
      );
      firefox-addons = pkgs.callPackage inputs.firefox-addons { };
    in
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # -----------------------------------------------------------------------
      catppuccin.firefox.enable = constants.catppuccin or false;
      catppuccin.firefox.flavor = constants.catppuccinFlavor or "mocha";
      catppuccin.firefox.accent = constants.catppuccinAccent or "mauve";
      # Since it is a gtk theme, no firefox.enable = false; is needed in stylix.nix
      # -----------------------------------------------------------------------

      # 🔑 Password Manager Integration
      # Connects Firefox to 'browserpass' for secure credential handling.
      # Currently disabled due to proton pass usage
      programs.browserpass.enable = false;

      programs.firefox = {
        enable = false;
        profiles.${constants.user} = {
          # 🔍 Search Configuration
          # Forces Google as default while keeping privacy options like Kagi and duck duck go available.
          search = {
            force = true; # Enforce custom search engine settings
            default = "kagi"; # Set Google as the default search engine
            privateDefault = "kagi"; # Set Kagi as the default for private browsing
            order = [
              "kagi"
              "google"
              "ddg"
            ]; # Preferred search engine order
            engines = {
              kagi = {
                name = "kagi";
                urls = [
                  {
                    template = "https://kagi.com/search?q={searchTerms}";
                  }
                ]; # Search URL template query parameter
                icon = "https://kagi.com/favicon.ico";
              };
              bing.metaData.hidden = true; # Hide unwanted search providers
            };
          };

          # 📑 Bookmarks
          bookmarks = { };

          # 🧩 Extensions
          # Declares essential plugins fetched from the nix flake inputs.
          # The name can be viewed in the url while the extension page in the store is opened
          # If that does not work search on "https://nur.nix-community.org/repos/rycee/" and use the "name" without version
          extensions = {
            force = true; # Forced to allow catppuccin to modify the firefox color scheme
            packages = with firefox-addons; [
              ublock-origin # Popular ad and tracker blocker
              proton-pass # Proton Pass password manager integration
              firefox-color # Custom Firefox themes and color schemes. Needed for catppuccin
              sponsorblock # Skips sponsored segments in videos on platforms like YouTube
              gesturefy # Mouse gesture navigation for enhanced browsing
              privacy-badger # Tracker blocking extension by EFF
              screenshot-capture-annotate # Screenshot capturing and annotation tool (awesome screenshot)
              multi-account-containers # Isolates browsing activities into separate containers
              behind-the-overlay-revival # Bypass popup overlays on websites
              #onetab # Save memory by converting tabs into a list
              simplelogin # Proton Mail's email alias manager
              kagi-search # Kagi search engine integration for private browsing
              new-tab-override # Customize the new tab page
            ];
          };

          # ⚙️ internal Firefox Settings (about:config)
          settings = {
            "browser.startup.homepage" = "https://kagi.com/";
            # 3= restore previous session | 1= homepage | 0= blank page
            "browser.startup.page" = 1;

            # Disable irritating first-run stuff
            "browser.disableResetPrompt" = true;
            "browser.download.panel.shown" = true;
            "browser.feeds.showFirstRunUI" = false;
            "browser.messaging-system.whatsNewPanel.enabled" = false;
            "browser.rights.3.shown" = true;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.defaultBrowserCheckCount" = 1;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.uitour.enabled" = false;
            "startup.homepage_override_url" = "";
            "trailhead.firstrun.didSeeAboutWelcome" = true;
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.bookmarks.addedImportButton" = true;

            # 🛡️ SECURE DNS (Quad9)
            "DnsOverHttpsMode" = "secure";
            "DnsOverHttpsTemplates" = "https://dns.quad9.net/dns-query";

            # Don't ask for download dir and force it to Downloads
            "browser.download.useDownloadDir" = true;
            "browser.download.folderList" = 2;
            "browser.download.dir" = "/home/${constants.user}/Downloads";
            "browser.download.lastDir" = "/home/${constants.user}/Downloads";

            # Disable crappy home activity stream page
            # hides the default promoted/suggested tiles on Firefox's new-tab screen from several major websites.
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
            ] (_: 1);

            # Disable some telemetry
            "app.shield.optoutstudies.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
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

            # DRM / Widevine for streaming services
            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;
            "media.gmp-widevinecdm.visible" = true;

            # Audio normalization
            "accessibility.typeaheadfind.enablesound" = false;
            "media.getusermedia.screensharing.allow_is_screen_content_sales" = false;

            # Disable fx accounts
            "identity.fxaccounts.enabled" = false;

            # Disable "save password" prompt
            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;
            "extensions.formautofill.addresses.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;

            # Harden
            "privacy.trackingprotection.enabled" = true;
            "dom.security.https_only_mode" = true;

            # Remove close button
            "browser.tabs.inTitlebar" = 0;

            # Vertical tabs
            "sidebar.verticalTabs" = true;
            "sidebar.revamp" = true;
            "sidebar.main.tools" = [
              "history"
              "bookmarks"
            ];

            # Toolbar placement: assigns buttons to specific navigation bar slots.
            # Pin extensions and show buttons
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
                  # "extension_one-tab_com-browser-action" # OneTab
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
              currentVersion = 23;
              newElementCount = 10;
            };
          };
        };
      };
    };
}
