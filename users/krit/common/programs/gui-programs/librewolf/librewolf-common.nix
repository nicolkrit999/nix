{ delib
, pkgs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.librewolf";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.stylix.targets.librewolf.profileNames = [ "default" "privacy" ];

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      addons = pkgs.firefox-addons;

      # ifEnabled cannot read config.home.homeDirectory; mirrors home-base.nix
      homeDir = "${if moduleSystem == "darwin" then "/Users" else "/home"}/${myconfig.constants.user}";

      searchConfig = {
        force = true;
        default = "kagi";
        privateDefault = "kagi";
        order = [
          "kagi"
          "ddg"
        ];
        engines = {
          "kagi" = {
            urls = [{ template = "https://kagi.com/search?q={searchTerms}"; }];
            icon = "https://kagi.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = [ "@k" ];
          };
          "wikipedia".metaData.hidden = true;
          "mojeek".metaData.hidden = true;
          "startpage".metaData.hidden = true;
        };
      };

      toolbarSettings = {
        "browser.uiCustomization.state" = builtins.toJSON {
          currentVersion = 23;
          newElementCount = 10;
          placements = {
            widget-overflow-fixed-list = [ ];
            nav-bar = [
              "back-button"
              "forward-button"
              "vertical-spacer"
              "home-button"
              "stop-reload-button"
              "urlbar-container"
              "downloads-button"
              "search_kagi_com-browser-action"
              "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
              "78272b6fa58f4a1abaac99321d503a20_proton_me-browser-action"
              "addon_simplelogin-browser-action"
              "unified-extensions-button"
            ];
            toolbar-menubar = [ "menubar-items" ];
            TabsToolbar = [ ];
            vertical-tabs = [ "tabbrowser-tabs" ];
          };
          seen = [
            "developer-button"
            "ublock0_raymondhill_net-browser-action"
            "_testpilot-containers-browser-action"
            "screenshot-button"
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
        "browser.startup.homepage" = "https://kagi.com/";
        "browser.compactmode.show" = true;
        "browser.uidensity" = 0;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.tabs.insertRelatedAfterCurrent" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "browser.warnOnQuit" = false;
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.warnOnCloseOther" = false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
        "browser.display.document_color_use" = 0;
        "ui.systemUsesDarkTheme" = if myconfig.constants.theme.polarity == "dark" then 1 else 0;

        "browser.download.useDownloadDir" = true;
        "browser.download.folderList" = 2;
        "browser.download.dir" = "${homeDir}/Downloads";
        "browser.download.lastDir" = "${homeDir}/Downloads";

        "extensions.autoDisableScopes" = 0;

        "identity.fxaccounts.enabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.system.showSponsored" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;

        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;

        "browser.tabs.inTitlebar" = 0;
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
        "sidebar.main.tools" = "history,bookmarks";

        "browser.urlbar.suggest.calculator" = true;

        "media.videocontrols.picture-in-picture.enabled" = true;

        "browser.contentblocking.category" = "strict";

        "network.trr.mode" = 2;
        "network.trr.uri" = "https://dns.quad9.net/dns-query";
      };
    in
    {
      xdg.desktopEntries."librewolf-privacy" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        name = "LibreWolf Privacy";
        genericName = "Web Browser";
        exec = "librewolf -P Privacy --no-remote";
        icon = "librewolf";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
        comment = "Launch LibreWolf in Hardened Privacy Mode";
      };

      programs.librewolf = {
        enable = true;

        profiles = {
          default = import ./profiles/librewolf-profile-default.nix {
            inherit addons searchConfig commonSettings;
          };

          privacy = import ./profiles/librewolf-profile-privacy.nix {
            inherit pkgs lib addons searchConfig commonSettings;
          };
        };
      };
    };
}
