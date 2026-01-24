{
  pkgs,
  lib,
  inputs,
  vars,
  ...
}:
let
  addons = pkgs.callPackage inputs.firefox-addons { };

  policyRoot = "/home/${vars.user}/.librewolf-policyroot";

  policiesJson = builtins.toJSON {
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;

      ExtensionSettings = {
        "*" = {
          installation_mode = "allowed";
        };
      };

      # Allow cookie permissions for the auth domains
      Cookies = {
        Allow = [
          "https://pocket-id.nicolkrit.ch"
          "https://nicolkrit.cloudflareaccess.com"

          # keep your other sites too
          "https://kagi.com"
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
          "https://protonmail.com"
          "https://account.protonmail.com"
          "https://protonmail.ch"
          "https://simplelogin.io"
          "https://app.simplelogin.io"
          "https://simplelogin.com"
          "https://auth.simplelogin.com"
          "https://nicolkrit.ch"
          "https://nas.nicolkrit.ch"
        ];
      };

      PopupBlocking = {
        Default = false;
        Allow = [
          "https://pocket-id.nicolkrit.ch"
          "https://nicolkrit.cloudflareaccess.com"
        ];
      };

      Preferences = {
        "network.cookie.cookieBehavior" = {
          Value = 0;
          Status = "locked";
        };
        "network.cookie.cookieBehavior.pbmode" = {
          Value = 0;
          Status = "locked";
        };
        "network.cookie.lifetimePolicy" = {
          Value = 0;
          Status = "locked";
        };

        "privacy.firstparty.isolate" = {
          Value = false;
          Status = "locked";
        };
        "privacy.partition.network_state" = {
          Value = false;
          Status = "locked";
        };

        "privacy.resistFingerprinting" = {
          Value = false;
          Status = "locked";
        };
        "privacy.fingerprintingProtection" = {
          Value = false;
          Status = "locked";
        };

        "browser.contentblocking.category" = {
          Value = "standard";
          Status = "locked";
        };
        "privacy.trackingprotection.enabled" = {
          Value = false;
          Status = "locked";
        };
        "privacy.trackingprotection.fingerprinting.enabled" = {
          Value = false;
          Status = "locked";
        };
        "privacy.trackingprotection.socialtracking.enabled" = {
          Value = false;
          Status = "locked";
        };
        "privacy.trackingprotection.cryptomining.enabled" = {
          Value = false;
          Status = "locked";
        };

        # Self-hosted / strict OIDC compatibility knobs
        "network.cookie.sameSite.laxByDefault" = {
          Value = false;
          Status = "locked";
        };
        "network.cookie.sameSite.noneRequiresSecure" = {
          Value = false;
          Status = "locked";
        };

        # Avoid DoH breaking reachability
        "network.trr.mode" = {
          Value = 5;
          Status = "locked";
        };

        # Referrers permissive for redirect flows
        "network.http.referer.XOriginPolicy" = {
          Value = 0;
          Status = "locked";
        };
        "network.http.referer.XOriginTrimmingPolicy" = {
          Value = 0;
          Status = "locked";
        };
      };
    };
  };

  # SEARCH
  searchConfig = {
    force = true;
    default = "kagi";
    privateDefault = "kagi";
    order = [
      "kagi"
      "ddg"
      "google"
      "perplexity"
    ];
    engines = {
      "kagi" = {
        urls = [ { template = "https://kagi.com/search?q={searchTerms}"; } ];
        icon = "https://kagi.com/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@k" ];
      };
      "perplexity" = {
        urls = [ { template = "https://www.perplexity.ai/search?q={searchTerms}"; } ];
        icon = "https://www.perplexity.ai/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@p" ];
      };
      "google".metaData.hidden = false;
      "duckduckgo".metaData.hidden = false;

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

  # UI LAYOUT
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
        "save-to-pocket-button"
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

  # COMMON PREFS (“junk off”)
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
    "browser.display.use_system_colors" = true;

    "ui.systemUsesDarkTheme" = if vars.polarity == "dark" then 1 else 0;
    "browser.in-content.dark-mode" = vars.polarity == "dark";

    "browser.download.useDownloadDir" = true;
    "browser.download.folderList" = 2;
    "browser.download.dir" = "/home/${vars.user}/Downloads";
    "browser.download.lastDir" = "/home/${vars.user}/Downloads";

    # Telemetry/junk off
    "extensions.pocket.enabled" = false;
    "identity.fxaccounts.enabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;

    # New tab junk off
    "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
    "browser.newtabpage.activity-stream.showSearch" = false;
    "browser.newtabpage.activity-stream.feeds.snippets" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.system.showSponsored" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;

    # Password manager off
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;

    # Vertical tabs
    "browser.tabs.inTitlebar" = 0;
    "sidebar.verticalTabs" = true;
    "sidebar.revamp" = true;

    "browser.urlbar.suggest.calculator" = true;
  };
in
{
  programs.browserpass.enable = false;

  xdg.desktopEntries."librewolf-privacy" = {
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

  home.file.".librewolf-policyroot/distribution/policies.json".text = policiesJson;

  programs.librewolf = {
    enable = true;

    package = pkgs.lib.makeOverridable (
      _args:
      pkgs.writeShellScriptBin "librewolf" ''
        set -eu
        export MOZ_APP_DISTRIBUTION="${policyRoot}"

        # fail loudly if policies aren’t there (no silent “nothing”)
        test -f "${policyRoot}/distribution/policies.json"

        exec ${pkgs.librewolf}/bin/librewolf "$@"
      ''
    ) { };

    profiles = {
      default = (
        import ./librewolf-profile-default.nix {
          inherit
            pkgs
            addons
            searchConfig
            commonSettings
            vars
            inputs
            ;
        }
      );

      privacy = (
        import ./librewolf-profile-privacy.nix {
          inherit
            pkgs
            addons
            searchConfig
            commonSettings
            vars
            inputs
            ;
        }
      );
    };
  };
}
