{ delib
, lib
, config
, options
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
  hasClaudeWrappers = options ? myconfig.krit.programs.claude-code-wrappers;
  nasOff = lib.genAttrs
    (lib.filter (n: options ? myconfig.krit.services.nas.${n}) [
      "desktop-borg-backup"
      "laptop-borg-backup"
      "opencloud-mount"
      "smb"
      "sshfs"
    ])
    (_: { enable = lib.mkForce false; });

  exitNodeWarn = pkgs.writeShellApplication {
    name = "secure-travel-exitnode-warn";
    runtimeInputs = [ pkgs.jq pkgs.libnotify pkgs.tailscale ];
    text = ''
      notify() {
        notify-send -u normal -a secure-travel \
          -h string:x-canonical-private-synchronous:secure-travel-vpn "$1" "$2"
      }

      pick="Pick one in Trayscale, or run: tailscale set --exit-node=<name>"

      if ! json=$(tailscale status --json 2>/dev/null); then
        notify "Tailscale is not running" "Traffic is NOT protected. Start tailscaled and log in. $pick"
        exit 0
      fi

      state=$(jq -r '.BackendState // "Unknown"' <<<"$json" 2>/dev/null || echo Unknown)
      if [ "$state" != "Running" ]; then
        notify "Tailscale is $state" "Traffic is NOT protected. Log in, then pick an exit node. $pick"
        exit 0
      fi

      active=$(jq '[.Peer[]? | select(.ExitNode == true)] | length' <<<"$json")
      if [ "$active" -eq 0 ]; then
        notify "No Tailscale exit node set" "Traffic is NOT protected. $pick"
      fi
    '';
  };
in
delib.module {
  name = "specializations.secure-travel";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.secure-travel.configuration = {
      system.nixos.tags = [ "secure-travel" ];

      # ---------------------------------------------------------
      # 1. 🛡️ KERNEL & SYSTEM HARDENING
      # ---------------------------------------------------------
      boot.kernel.sysctl = {
        # Kernel hardening
        "kernel.kptr_restrict" = 2; # Hide kernel pointers from unprivileged users
        "kernel.dmesg_restrict" = 1; # Restrict dmesg to root only
        "kernel.sysrq" = 4; # Only allow SAK (Secure Attention Key)
        "kernel.perf_event_paranoid" = 3; # Disable perf events for unprivileged users
        "kernel.unprivileged_bpf_disabled" = 1; # Disable BPF for unprivileged users
        "net.core.bpf_jit_harden" = 2; # Harden BPF JIT compiler
        "kernel.yama.ptrace_scope" = 2; # Restrict ptrace to root only

        # Network hardening - ICMP redirects (prevent MITM route hijacking)
        "net.ipv4.conf.all.accept_redirects" = 0; # Ignore IPv4 ICMP redirects
        "net.ipv4.conf.default.accept_redirects" = 0; # Ignore IPv4 ICMP redirects
        "net.ipv6.conf.all.accept_redirects" = 0; # Ignore IPv6 ICMP redirects
        "net.ipv6.conf.default.accept_redirects" = 0; # Ignore IPv6 ICMP redirects
        "net.ipv4.conf.all.send_redirects" = 0; # Don't send ICMP redirects
        "net.ipv4.conf.default.send_redirects" = 0; # Don't send ICMP redirects

        # Network hardening - Source routing (prevent IP spoofing)
        "net.ipv4.conf.all.accept_source_route" = 0; # Reject source-routed packets
        "net.ipv4.conf.default.accept_source_route" = 0; # Reject source-routed packets
        "net.ipv6.conf.all.accept_source_route" = 0; # Reject source-routed packets
        "net.ipv6.conf.default.accept_source_route" = 0; # Reject source-routed packets

        # Network hardening - Reverse path filtering (anti-spoofing)
        "net.ipv4.conf.all.rp_filter" = 1; # Drop packets with non-routable source
        "net.ipv4.conf.default.rp_filter" = 1; # Drop packets with non-routable source

        # Network hardening - Misc protections
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Ignore broadcast pings (smurf attack)
        "net.ipv4.tcp_syncookies" = 1; # Protect against SYN flood attacks
        "net.ipv4.conf.all.log_martians" = 1; # Log packets with impossible addresses
        "net.ipv4.conf.default.log_martians" = 1; # Log packets with impossible addresses
      };

      # Lock root account
      users.users.root = {
        hashedPassword = lib.mkForce "!";
        hashedPasswordFile = lib.mkForce null;
      };

      # ---------------------------------------------------------
      # 2. 🖥️ DESKTOP & PROGRAMS (GNOME only - most secure DE)
      # ---------------------------------------------------------
      myconfig = {
        programs = {
          # Use GNOME (well-audited, large security team)
          gnome.enable = lib.mkForce true;

          # Disable other DEs/WMs
          caelestia.enable = lib.mkForce false;
          cosmic.enable = lib.mkForce false;
          hyprland.enable = lib.mkForce false;
          kde.enable = lib.mkForce false;
          mango.enable = lib.mkForce false;
          niri.enable = lib.mkForce false;
          noctalia.enable = lib.mkForce false;

          # Disable attack surface programs
          claude-code.enable = lib.mkForce false; # External API calls
          claude-desktop.enable = lib.mkForce false; # External API calls
          codex.enable = lib.mkForce false; # External API calls
          google-antigravity.enable = lib.mkForce false; # AI agent IDE, external API calls
          headroom.enable = lib.mkForce false; # Proxy for external API calls
          herdr.enable = lib.mkForce false; # AI agent multiplexer
          nix-alien.enable = lib.mkForce false; # Same concern
          nix-ld.enable = lib.mkForce false; # Allows unpatched binaries
        };

        # ---------------------------------------------------------
        # 3. 🔧 SERVICES
        # ---------------------------------------------------------
        services = {
          # Hyprland-session services, unused under GNOME
          coffee.enable = lib.mkForce false;
          hypridle.enable = lib.mkForce false;

          localsend.enable = lib.mkForce false; # I-08: opens LAN ports

          # Tailscale is the VPN: a Mullvad exit node is picked by hand and
          # the advisory user unit below warns while none is active.
          tailscale.enable = lib.mkForce true;
        };

        # Bluetooth stays available (headphones) but the radio is off at boot.
        bluetooth = {
          enable = lib.mkForce true;
          autoEnableOnBoot = lib.mkForce false;
        };
      };

      imports =
        lib.optional hasClaudeWrappers
          {
            myconfig.krit.programs.claude-code-wrappers.enable = lib.mkForce false; # Bundles claude
          }
        ++ lib.optional (nasOff != { }) {
          # I-09: the NAS consumers are tailnet-only and stay off in travel mode.
          myconfig.krit.services.nas = nasOff;
        };

      # I-08/I-09: the travel profile exposes no listening ports; sshd and
      # avahi are pure inbound attack surface.
      services = {
        avahi.enable = lib.mkForce false;
        gnome = {
          gnome-remote-desktop.enable = lib.mkForce false;
          gnome-user-share.enable = lib.mkForce false;
        };
        openssh.enable = lib.mkForce false;
        resolved = {
          enable = true;
          settings.Resolve = {
            DNSSEC = lib.mkForce "allow-downgrade"; # DNSSEC with captive portal fallback
            FallbackDNS = lib.mkForce "1.1.1.1 8.8.8.8"; # Fallback for captive portals
            DNSOverTLS = lib.mkForce "opportunistic"; # DoT when available, plain for portals
            LLMNR = lib.mkForce "false";
            MulticastDNS = lib.mkForce "false";
          };
        };
        tailscale.openFirewall = lib.mkForce false; # Outbound only; DERP relays still work
      };

      environment.systemPackages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        pkgs.tor-browser
      ];

      # ---------------------------------------------------------
      # 4. 🌐 DNS & NETWORK (MAC randomization + firewall)
      # ---------------------------------------------------------
      networking = {
        nameservers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ]; # Quad9

        networkmanager = {
          wifi.macAddress = "random"; # Randomize MAC on each connection
          ethernet.macAddress = "random";
        };

        firewall = {
          enable = true;
          allowedTCPPorts = lib.mkForce [ ];
          allowedUDPPorts = lib.mkForce [ ];
          logRefusedConnections = true; # Log blocked connections
          logRefusedPackets = true;
          trustedInterfaces = lib.mkForce [ "lo" ]; # loopback only; tailscale0 is not trusted while travelling
        };
      };

      virtualisation.docker.enable = lib.mkForce false;

      # ---------------------------------------------------------
      # 5. 👤 HOME-MANAGER
      # ---------------------------------------------------------
      home-manager.users.${myUserName} = { pkgs, lib, ... }: {
        home.packages = [ pkgs.trayscale ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [ pkgs.tor-browser ];

        systemd.user = {
          services.secure-travel-exitnode-warn = {
            Unit = {
              Description = "Warn when no Tailscale exit node is active (secure-travel)";
              After = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = lib.getExe exitNodeWarn;
            };
          };
          timers.secure-travel-exitnode-warn = {
            Unit = {
              Description = "Periodic Tailscale exit node check (secure-travel)";
              PartOf = [ "graphical-session.target" ];
            };
            Timer = {
              OnActiveSec = "45s";
              OnUnitActiveSec = "2min";
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        };
      };
    };
  };
}
