{ delib, lib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
delib.module {
  name = "krit.programs.zen-browser";

  home.ifEnabled = { cfg, ... }: {
    programs.zen-browser.profiles.default = {
      pinsForce = true;
      pins = lib.filterAttrs (_: pin: !cfg.universityOnly || (pin.workspace or null) == "10000000-0000-4000-8000-000000000004") {

        # ── Folders ─────────────────────────────────────────────────────────

        # General workspace
        "Utilities" = {
          id = "30000000-0000-4000-8000-000000000004";
          isGroup = true;
          folderIcon = "🔧";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 200;
        };
        "Self hosting" = {
          id = "30000000-0000-4000-8000-000000000003";
          isGroup = true;
          folderIcon = "💿️";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 300;
        };
        "Social & Entertainment" = {
          id = "30000000-0000-4000-8000-000000000001";
          isGroup = true;
          folderIcon = "📺️";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 400;
        };
        "Personal finance" = {
          id = "30000000-0000-4000-8000-000000000002";
          isGroup = true;
          folderIcon = "🏦";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 500;
        };
        "AI" = {
          id = "30000000-0000-4000-8000-000000000005";
          isGroup = true;
          folderIcon = "🤖";
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 600;
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
        "iCorsi Essential" = {
          id = "20000000-0000-4000-8000-000000000014";
          title = "iCorsi";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 100;
          isEssential = true;
        };
        "Portale Studenti Essential" = {
          id = "20000000-0000-4000-8000-000000000015";
          title = "Portale Studenti";
          url = "https://portalestudenti.supsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 101;
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
        "Linkwarden Essential" = {
          id = "20000000-0000-4000-8000-000000000007";
          title = "Linkwarden";
          url = "https://linkwarden.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 103;
          isEssential = true;
        };
        "Glance Essential" = {
          id = "20000000-0000-4000-8000-000000000008";
          title = "Glance";
          url = "https://glance.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 104;
          isEssential = true;
        };
        "NAS Essential" = {
          id = "20000000-0000-4000-8000-000000000009";
          title = "NAS";
          url = "https://ug.link/nicolnas";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 105;
          isEssential = true;
        };
        "Hevy" = {
          id = "20000000-0000-4000-8000-000000000016";
          url = "https://hevy.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 106;
          isEssential = true;
        };
        "Portainer Essential" = {
          id = "20000000-0000-4000-8000-00000000000a";
          title = "Portainer";
          url = "https://portainer.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 107;
          isEssential = true;
        };
        "Claude" = {
          id = "20000000-0000-4000-8000-00000000000b";
          url = "https://claude.ai/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 108;
          isEssential = true;
        };
        "Reddit Essential" = {
          id = "20000000-0000-4000-8000-00000000000c";
          title = "Reddit";
          url = "https://www.reddit.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 109;
          isEssential = true;
        };
        "YouTube Essential" = {
          id = "20000000-0000-4000-8000-00000000000d";
          title = "YouTube";
          url = "https://www.youtube.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 110;
          isEssential = true;
        };
        "YouTube Music Essential" = {
          id = "20000000-0000-4000-8000-00000000000e";
          title = "YouTube Music";
          url = "https://music.youtube.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 111;
          isEssential = true;
        };
        "GitHub Essential" = {
          id = "20000000-0000-4000-8000-00000000000f";
          title = "GitHub";
          url = "https://www.github.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 112;
          isEssential = true;
        };
        "Actual Budget Essential" = {
          id = "20000000-0000-4000-8000-000000000010";
          title = "Actual Budget";
          url = "https://budget.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 113;
          isEssential = true;
        };
        "UBS Essential" = {
          id = "20000000-0000-4000-8000-000000000011";
          title = "UBS";
          url = "https://ebanking-ch2.ubs.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 114;
          isEssential = true;
        };
        "Raiffeisen Essential" = {
          id = "20000000-0000-4000-8000-000000000012";
          title = "Raiffeisen";
          url = "https://login.raiffeisen.ch/en/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 115;
          isEssential = true;
        };
        "SBB Essential" = {
          id = "20000000-0000-4000-8000-000000000013";
          title = "SBB";
          url = "https://www.sbb.ch/en/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          position = 116;
          isEssential = true;
        };

        # ── Utilities ─────────────────────────────────────────────────────

        "Unifi Cloud" = {
          id = "40000000-0000-4000-8000-000000000036";
          url = "https://unifi.ui.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 101;
        };
        "Tailscale Admin" = {
          id = "40000000-0000-4000-8000-000000000034";
          url = "https://console.tailscale.com/admin/machines";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 102;
        };
        "DownGit" = {
          id = "40000000-0000-4000-8000-0000000000b0";
          url = "https://downgit.github.io";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 103;
        };
        "Git Rawify" = {
          id = "40000000-0000-4000-8000-000000000031";
          url = "https://git-rawify.vercel.app/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 104;
        };
        "Cloudflare - dashboard" = {
          id = "40000000-0000-4000-8000-000000000035";
          url = "https://dash.cloudflare.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000004";
          position = 105;
        };

        # ── Self hosting ──────────────────────────────────────────────────

        "Glance" = {
          id = "40000000-0000-4000-8000-000000000025";
          url = "https://glance.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 101;
        };
        "NAS" = {
          id = "40000000-0000-4000-8000-000000000021";
          url = "https://ug.link/nicolnas";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 102;
        };
        "Linkwarden" = {
          id = "40000000-0000-4000-8000-00000000002c";
          url = "https://linkwarden.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 103;
        };
        "Budget" = {
          id = "40000000-0000-4000-8000-0000000000c1";
          url = "https://budget.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 104;
        };
        "Promemoria" = {
          id = "40000000-0000-4000-8000-000000000033";
          url = "https://promemoria.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 105;
        };
        "Stirling PDF" = {
          id = "40000000-0000-4000-8000-0000000000ca";
          url = "https://stirling-pdf.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 106;
        };
        "Gokapi" = {
          id = "40000000-0000-4000-8000-0000000000c2";
          url = "https://gokapi.nicolkrit.ch/login";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 107;
        };
        "PrivateBin" = {
          id = "40000000-0000-4000-8000-00000000002a";
          url = "https://privatebin.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 108;
        };
        "Gitea" = {
          id = "40000000-0000-4000-8000-000000000029";
          url = "https://gitea.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 109;
        };
        "Jellyfin" = {
          id = "40000000-0000-4000-8000-000000000022";
          url = "https://jellyfin.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 110;
        };
        "Foto" = {
          id = "40000000-0000-4000-8000-000000000023";
          url = "https://foto.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 111;
        };
        "PaperlessNGX" = {
          id = "40000000-0000-4000-8000-0000000000c3";
          url = "https://paperlessngx.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 112;
        };
        "OmniTools" = {
          id = "40000000-0000-4000-8000-000000000032";
          url = "https://omnitools.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 113;
        };
        "IT Tools" = {
          id = "40000000-0000-4000-8000-000000000030";
          url = "https://it-tools.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 114;
        };
        "ByteStash" = {
          id = "40000000-0000-4000-8000-0000000000c4";
          url = "https://bytestash.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 115;
        };
        "Portainer" = {
          id = "40000000-0000-4000-8000-000000000026";
          url = "https://portainer.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 116;
        };
        "Uptime Kuma" = {
          id = "40000000-0000-4000-8000-0000000000c5";
          url = "https://uptime-kuma.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 117;
        };
        "Beszel" = {
          id = "40000000-0000-4000-8000-000000000024";
          url = "https://beszel.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 118;
        };
        "Tugtainer" = {
          id = "40000000-0000-4000-8000-000000000027";
          url = "https://tugtainer.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 119;
        };
        "Duplicati" = {
          id = "40000000-0000-4000-8000-000000000028";
          url = "https://duplicati.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 120;
        };
        "Adguard" = {
          id = "40000000-0000-4000-8000-000000000037";
          url = "https://adguard.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 121;
        };
        "Traefik" = {
          id = "40000000-0000-4000-8000-00000000002e";
          url = "https://traefik.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 122;
        };
        "Pocket ID" = {
          id = "40000000-0000-4000-8000-0000000000c6";
          url = "https://pocket-id.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 123;
        };
        "Grafana" = {
          id = "40000000-0000-4000-8000-000000000038";
          url = "https://grafana.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 124;
        };
        "qBittorrent" = {
          id = "40000000-0000-4000-8000-00000000002b";
          url = "https://qbit-torrent.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 125;
        };
        "Home Assistant" = {
          id = "40000000-0000-4000-8000-00000000002f";
          url = "https://home-assistant.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 126;
        };
        "Fitness" = {
          id = "40000000-0000-4000-8000-00000000002d";
          url = "https://sparkyfitness.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000003";
          position = 127;
        };

        # ── Social & Entertainment ────────────────────────────────────────

        "YouTube" = {
          id = "40000000-0000-4000-8000-000000000002";
          url = "https://www.youtube.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 101;
        };
        "YouTube Music" = {
          id = "40000000-0000-4000-8000-000000000003";
          url = "https://music.youtube.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 102;
        };
        "Twitch" = {
          id = "40000000-0000-4000-8000-000000000004";
          url = "https://www.twitch.tv/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 103;
        };
        "Reddit" = {
          id = "40000000-0000-4000-8000-000000000001";
          url = "https://www.reddit.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000001";
          position = 104;
        };

        # ── Personal finance ──────────────────────────────────────────────

        "Actual Budget" = {
          id = "40000000-0000-4000-8000-000000000013";
          url = "https://budget.nicolkrit.ch/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 101;
        };
        "Raiffeisen" = {
          id = "40000000-0000-4000-8000-000000000012";
          url = "https://login.raiffeisen.ch/it";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 102;
        };
        "UBS" = {
          id = "40000000-0000-4000-8000-000000000011";
          url = "https://ebanking-ch2.ubs.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000002";
          position = 103;
        };

        # ── AI ────────────────────────────────────────────────────────────

        "Claude AI" = {
          id = "40000000-0000-4000-8000-0000000000b1";
          url = "https://claude.ai/new";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 101;
        };
        "Claude Console" = {
          id = "40000000-0000-4000-8000-0000000000b2";
          url = "https://platform.claude.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 102;
        };
        "Claude agent floor" = {
          id = "40000000-0000-4000-8000-0000000000bd";
          url = "http://localhost:4317/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 103;
        };
        "Claude mem" = {
          id = "40000000-0000-4000-8000-0000000000be";
          url = "http://localhost:37700/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 104;
        };
        "Claude headroom" = {
          id = "40000000-0000-4000-8000-0000000000bf";
          url = "http://localhost:8787/dashboard";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 105;
        };
        "Claude context 7" = {
          id = "40000000-0000-4000-8000-0000000000c0";
          url = "http://localhost:4747/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 106;
        };
        "Copilot" = {
          id = "40000000-0000-4000-8000-0000000000b3";
          url = "https://github.com/copilot";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 107;
        };
        "ChatGPT" = {
          id = "40000000-0000-4000-8000-0000000000b4";
          url = "https://chatgpt.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 108;
        };
        "Gemini" = {
          id = "40000000-0000-4000-8000-0000000000b5";
          url = "https://gemini.google.com/app";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 109;
        };
        "Grok" = {
          id = "40000000-0000-4000-8000-0000000000b6";
          url = "https://grok.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 110;
        };
        "Perplexity" = {
          id = "40000000-0000-4000-8000-0000000000b7";
          url = "https://www.perplexity.ai";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 111;
        };
        "Mistral" = {
          id = "40000000-0000-4000-8000-0000000000b8";
          url = "https://chat.mistral.ai/chat";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 112;
        };
        "Deepseek" = {
          id = "40000000-0000-4000-8000-0000000000b9";
          url = "https://www.deepseek.com/en/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 113;
        };
        "GLM" = {
          id = "40000000-0000-4000-8000-0000000000ba";
          url = "https://chat.z.ai/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 114;
        };
        "Kimi" = {
          id = "40000000-0000-4000-8000-0000000000bb";
          url = "https://www.kimi.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 115;
        };
        "Openrouter" = {
          id = "40000000-0000-4000-8000-0000000000bc";
          url = "https://openrouter.ai/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001";
          folderParentId = "30000000-0000-4000-8000-000000000005";
          position = 116;
        };

        # ── Family ────────────────────────────────────────────────────────

        "Bluewin Mail" = {
          id = "40000000-0000-4000-8000-000000000091";
          url = "https://email.bluewin.ch/appsuite/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 101;
        };
        "Casa" = {
          id = "40000000-0000-4000-8000-000000000092";
          url = "https://casa.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 102;
        };
        "Foto Root Family" = {
          id = "40000000-0000-4000-8000-000000000099";
          title = "Foto";
          url = "https://foto.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 103;
        };
        "Jellyfin Family" = {
          id = "40000000-0000-4000-8000-00000000009d";
          title = "Jellyfin";
          url = "https://jellyfin.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 104;
        };
        "Gokapi Family" = {
          id = "40000000-0000-4000-8000-0000000000c7";
          title = "Gokapi";
          url = "https://gokapi.nicolkrit.ch/login";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 105;
        };
        "Mealie" = {
          id = "40000000-0000-4000-8000-000000000094";
          url = "https://ricette.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 106;
        };
        "Grocy" = {
          id = "40000000-0000-4000-8000-00000000009b";
          url = "https://grocy.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 107;
        };
        "Navidrome" = {
          id = "40000000-0000-4000-8000-00000000009f";
          url = "https://navidrome.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 108;
        };
        "Kavita" = {
          id = "40000000-0000-4000-8000-0000000000c8";
          url = "https://kavita.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 109;
        };
        "Surmai" = {
          id = "40000000-0000-4000-8000-0000000000a5";
          url = "https://viaggi.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 110;
        };
        "Budget Family" = {
          id = "40000000-0000-4000-8000-000000000098";
          title = "Budget";
          url = "https://budget.nicolkrit.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002";
          folderParentId = "30000000-0000-4000-8000-000000000021";
          position = 111;
        };

        # ── Pc building ───────────────────────────────────────────────────

        "PCPartPicker" = {
          id = "40000000-0000-4000-8000-000000000041";
          url = "https://pcpartpicker.com/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000031";
          position = 101;
        };

        # ── IT services ───────────────────────────────────────────────────

        "Appuntamenti" = {
          id = "40000000-0000-4000-8000-000000000051";
          url = "https://appuntamenti.nicolkrit.ch/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000032";
          position = 101;
        };

        # ── MK Ticino ─────────────────────────────────────────────────────

        "Tornei" = {
          id = "40000000-0000-4000-8000-000000000061";
          url = "https://eventi.nicolkrit.ch/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003";
          folderParentId = "30000000-0000-4000-8000-000000000033";
          position = 101;
        };

        # ── University resources ──────────────────────────────────────────

        "iCorsi" = {
          id = "40000000-0000-4000-8000-000000000071";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 101;
        };
        "Portale Studenti" = {
          id = "40000000-0000-4000-8000-000000000072";
          url = "https://portalestudenti.supsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 102;
        };
        "Outlook Mail" = {
          id = "40000000-0000-4000-8000-000000000073";
          url = "https://outlook.office.com/mail/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 103;
        };
        "Mensa" = {
          id = "40000000-0000-4000-8000-0000000000c9";
          url = "https://menu.1908.ch/usi-supsi#italiano/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 104;
        };

        # ── Personal resources ────────────────────────────────────────────

        "OpenCloud" = {
          id = "40000000-0000-4000-8000-000000000081";
          url = "https://opencloud.nicolkrit.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000042";
          position = 101;
        };

      };
    };
  };
}
