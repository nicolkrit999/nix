{ delib
, lib
, config
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
in
delib.module {
  name = "krit.specializations.secure-travel";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;

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
      myconfig.programs = {
        # Use GNOME (well-audited, large security team)
        gnome.enable = lib.mkForce true;

        # Disable other DEs/WMs
        hyprland.enable = lib.mkForce false;
        niri.enable = lib.mkForce false;
        kde.enable = lib.mkForce false;
        cosmic.enable = lib.mkForce false;
        caelestia.enable = lib.mkForce false;
        noctalia.enable = lib.mkForce false;

        # Disable attack surface programs
        nix-ld.enable = lib.mkForce false; # Allows unpatched binaries
        nix-alien.enable = lib.mkForce false; # Same concern
        claude-code.enable = lib.mkForce false; # External API calls
      };

      # ---------------------------------------------------------
      # 3. 🔧 SERVICES
      # ---------------------------------------------------------
      myconfig.services = {
        # Disable Hyprland-specific
        hyprlock.enable = lib.mkForce false;
        hypridle.enable = lib.mkForce false;

        # Disable network services
        tailscale.enable = lib.mkForce false; # Using ProtonVPN instead
      };

      # Disable other toplevel modules
      myconfig.bluetooth.enable = lib.mkForce false; # Attack vector on public WiFi
      myconfig.guest.enable = lib.mkForce false; # Guest accounts are risky

      # ---------------------------------------------------------
      # 4. 👤 KRIT USER MODULES
      # ---------------------------------------------------------
      myconfig.krit.programs = {
        pwas.enable = lib.mkForce false; # Less sandboxed than browser tabs
      };

      myconfig.krit.services = {
        logitech.enable = lib.mkForce false; # USB driver attack surface

        nas = {
          owncloud.enable = lib.mkForce false;
          smb.enable = lib.mkForce false;
          sshfs.enable = lib.mkForce false;
          laptop-borg-backup.enable = lib.mkForce false;
          desktop-borg-backup.enable = lib.mkForce false;
        };

        desktop.flatpak.enable = lib.mkForce false;
        laptop.flatpak.enable = lib.mkForce false;
      };

      myconfig.krit.system = {
        virtualisation.enable = lib.mkForce false; # Reduces attack surface
      };

      # ---------------------------------------------------------
      # 5. 🔒 VPN: ProtonVPN + Soft Kill Switch
      # ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        protonvpn-gui
        tor-browser
      ];

      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeShellScript "vpn-killswitch" ''
            #!/bin/sh
            INTERFACE=$1
            STATUS=$2

            if [ "$INTERFACE" = "proton0" ] || [ "$INTERFACE" = "tun0" ]; then
              if [ "$STATUS" = "down" ]; then
                ${pkgs.libnotify}/bin/notify-send -u critical "VPN Disconnected" "ProtonVPN connection lost. Traffic is NOT protected."
              elif [ "$STATUS" = "up" ]; then
                ${pkgs.libnotify}/bin/notify-send -u normal "VPN Connected" "ProtonVPN is active. Traffic is protected."
              fi
            fi
          '';
          type = "basic";
        }
      ];

      # ---------------------------------------------------------
      # 6. 🌐 DNS & NETWORK
      # ---------------------------------------------------------
      networking = {
        nameservers = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ]; # Quad9

        networkmanager = {
          wifi.macAddress = "random"; # Randomize MAC on each connection
          ethernet.macAddress = "random";
        };

        firewall = {
          enable = true;
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ ];
          logRefusedConnections = true; # Log blocked connections
          logRefusedPackets = true;
        };
      };

      services.resolved = {
        enable = true;
        dnssec = lib.mkForce "allow-downgrade"; # DNSSEC with captive portal fallback
        domains = lib.mkForce [ "~." ]; # Route all DNS through resolved
        fallbackDns = lib.mkForce [ "1.1.1.1" "8.8.8.8" ]; # Fallback for captive portals
        dnsovertls = lib.mkForce "opportunistic"; # DoT when available, plain for portals
      };

      # ---------------------------------------------------------
      # 7. 👤 HOME-MANAGER
      # ---------------------------------------------------------
      home-manager.users.${myUserName} = { pkgs, ... }: {
        home.packages = with pkgs; [ tor-browser ];

        # GNOME auto-start ProtonVPN
        xdg.configFile."autostart/protonvpn.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=ProtonVPN
          Exec=sh -c 'sleep 3 && protonvpn-app --start-minimized'
          Hidden=false
          NoDisplay=false
          X-GNOME-Autostart-enabled=true
        '';
      };
    };
  };
}
