{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Pins/folders write to zen-sessions.jsonlz4; Zen locks the file while running.
# After pkill zen-beta, wait until ALL zen processes fully exit, then rebuild.
#
# Folders need ≥1 child pin — Zen drops empty folders on session save.
# Essential pins (isEssential=true): favicon-only uncloseable icons at sidebar top.
# Folder child pins (folderParentId=<folder-id>): appear inside the folder.
# Both can coexist for the same URL using different UUIDs.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      pinsForce = true;
      pins = {

        # ── Folders ─────────────────────────────────────────────────────────

        # General workspace
        "Social & Entertainment" = {
          id = "30000000-0000-4000-8000-000000000001";
          isGroup = true;
          folderIcon = "📺️";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 200;
        };
        "Personal finance" = {
          id = "30000000-0000-4000-8000-000000000002";
          isGroup = true;
          folderIcon = "🏦";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 300;
        };
        "Self hosting" = {
          id = "30000000-0000-4000-8000-000000000003";
          isGroup = true;
          folderIcon = "💿️";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 400;
        };
        "Utilities" = {
          id = "30000000-0000-4000-8000-000000000004";
          isGroup = true;
          folderIcon = "🔧";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 500;
        };

        # Secondary workspace
        "Family" = {
          id = "30000000-0000-4000-8000-000000000021";
          isGroup = true;
          folderIcon = "👨‍👩‍👧";
          workspace = "10000000-0000-4000-8000-000000000002";
          position = 200;
        };

        # Work workspace
        "Pc building" = {
          id = "30000000-0000-4000-8000-000000000031";
          isGroup = true;
          folderIcon = "🖥️";
          workspace = "10000000-0000-4000-8000-000000000003";
          position = 200;
        };
        "IT services" = {
          id = "30000000-0000-4000-8000-000000000032";
          isGroup = true;
          folderIcon = "🛠️";
          workspace = "10000000-0000-4000-8000-000000000003";
          position = 300;
        };
        "MK Ticino" = {
          id = "30000000-0000-4000-8000-000000000033";
          isGroup = true;
          folderIcon = "📅";
          workspace = "10000000-0000-4000-8000-000000000003";
          position = 400;
        };

        # University workspace
        "University resources" = {
          id = "30000000-0000-4000-8000-000000000041";
          isGroup = true;
          folderIcon = "🎓";
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 200;
        };
        "Personal resources" = {
          id = "30000000-0000-4000-8000-000000000042";
          isGroup = true;
          folderIcon = "📔";
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 300;
        };

        # ── Essential pins ───────────────────────────────────────────────────

        "Swisscom" = {
          id = "20000000-0000-4000-8000-000000000002";
          url = "https://www.swisscom.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          position = 100;
          isEssential = true;
        };
        "Proton Mail" = {
          id = "20000000-0000-4000-8000-000000000005";
          url = "https://mail.proton.me/u/0/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 101;
          isEssential = true;
        };
        "Proton Pass" = {
          id = "20000000-0000-4000-8000-000000000006";
          url = "https://pass.proton.me/u/0/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 102;
          isEssential = true;
        };

        # ── Social & Entertainment ───────────────────────────────────────────

        "Reddit" = {
          id = "40000000-0000-4000-8000-000000000001";
          url = "https://www.reddit.com/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 101;
        };
        "YouTube" = {
          id = "40000000-0000-4000-8000-000000000002";
          url = "https://www.youtube.com/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 102;
        };
        "YouTube Music" = {
          id = "40000000-0000-4000-8000-000000000003";
          url = "https://music.youtube.com/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 103;
        };
        "Twitch" = {
          id = "40000000-0000-4000-8000-000000000004";
          url = "https://www.twitch.tv/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 104;
        };
        "Apple Music" = {
          id = "40000000-0000-4000-8000-000000000005";
          url = "https://music.apple.com/ch/home?l=en";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 105;
        };

        # ── Personal finance ─────────────────────────────────────────────────

        "UBS" = {
          id = "40000000-0000-4000-8000-000000000011";
          url = "https://ebanking-ch2.ubs.com/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 101;
        };
        "Raiffeisen" = {
          id = "40000000-0000-4000-8000-000000000012";
          url = "https://login.raiffeisen.ch/it";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 102;
        };
        "Actual Budget" = {
          id = "40000000-0000-4000-8000-000000000013";
          url = "https://budget.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 103;
        };

        # ── Self hosting ─────────────────────────────────────────────────────

        "NAS" = {
          id = "40000000-0000-4000-8000-000000000021";
          url = "https://nas.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 101;
        };
        "Jellyfin" = {
          id = "40000000-0000-4000-8000-000000000022";
          url = "https://jellyfin.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 102;
        };
        "Foto" = {
          id = "40000000-0000-4000-8000-000000000023";
          url = "https://foto.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 103;
        };
        "Beszel" = {
          id = "40000000-0000-4000-8000-000000000024";
          url = "https://beszel.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 104;
        };
        "Glance" = {
          id = "40000000-0000-4000-8000-000000000025";
          url = "https://glance.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 105;
        };
        "Portainer" = {
          id = "40000000-0000-4000-8000-000000000026";
          url = "https://portainer.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 106;
        };
        "Tugtainer" = {
          id = "40000000-0000-4000-8000-000000000027";
          url = "https://tugtainer.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 107;
        };
        "Duplicati" = {
          id = "40000000-0000-4000-8000-000000000028";
          url = "https://duplicati.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 108;
        };
        "Gitea" = {
          id = "40000000-0000-4000-8000-000000000029";
          url = "https://gitea.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 109;
        };
        "PrivateBin" = {
          id = "40000000-0000-4000-8000-00000000002a";
          url = "https://privatebin.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 110;
        };
        "qBittorrent" = {
          id = "40000000-0000-4000-8000-00000000002b";
          url = "https://qbittorrent.nicolkrit.ch/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 111;
        };

        # ── Utilities ────────────────────────────────────────────────────────

        "Git Rawify" = {
          id = "40000000-0000-4000-8000-000000000031";
          url = "https://git-rawify.vercel.app/";
          container = 1;
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 101;
        };

        # ── Pc building ──────────────────────────────────────────────────────
        # PCPartPicker moved here from essential pins.

        "PCPartPicker" = {
          id = "40000000-0000-4000-8000-000000000041";
          url = "https://pcpartpicker.com/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000031";
          position = 101;
        };

        # ── IT services ──────────────────────────────────────────────────────

        "Appuntamenti" = {
          id = "40000000-0000-4000-8000-000000000051";
          url = "https://appuntamenti.nicolkrit.ch/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000032";
          position = 101;
        };

        # ── MK Ticino ────────────────────────────────────────────────────────

        "Tornei" = {
          id = "40000000-0000-4000-8000-000000000061";
          url = "https://eventi.nicolkrit.ch/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000033";
          position = 101;
        };

        # ── University resources ─────────────────────────────────────────────

        "iCorsi" = {
          id = "40000000-0000-4000-8000-000000000071";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 101;
        };

        # ── Family ───────────────────────────────────────────────────────────

        "Bluewin Mail" = {
          id = "40000000-0000-4000-8000-000000000091";
          url = "https://email.bluewin.ch/appsuite/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 101;
        };

        # ── Personal resources ───────────────────────────────────────────────

        "ownCloud" = {
          id = "40000000-0000-4000-8000-000000000081";
          url = "https://owncloud.nicolkrit.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000042";
          position = 101;
        };

      };
    };
  };
}
