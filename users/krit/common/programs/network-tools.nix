{ delib, lib, pkgs, moduleSystem, ... }:
let
  # Reapplies two settings on the Xiaomi TV Box S (3rd Gen, Google TV) that
  # reset every time the box reboots: fixed-to-user-rotation (otherwise locks
  # the UI back to landscape) and the SYSTEM_ALERT_WINDOW appop for
  # orientationfaker (the overlay it draws needs it to stay visible). Network
  # ADB doesn't care about the host OS, so it works on Linux and macOS alike.
  tvPortrait = pkgs.writeShellApplication {
    name = "tv-portrait";
    runtimeInputs = [ pkgs.android-tools pkgs.coreutils ];
    text = ''
      TV="192.168.10.33:5555"

      adb disconnect "$TV" >/dev/null 2>&1 || true
      adb connect "$TV"

      if ! adb -s "$TV" get-state >/dev/null 2>&1; then
        echo "Offline, restarting adb server..."
        adb kill-server
        adb connect "$TV"
      fi

      if ! timeout 15 adb -s "$TV" wait-for-device; then
        echo "Error: $TV did not come online within 15s (is the TV box powered on?)" >&2
        exit 1
      fi

      adb -s "$TV" shell wm fixed-to-user-rotation disabled
      adb -s "$TV" shell appops set net.mm2d.android.orientationfaker SYSTEM_ALERT_WINDOW allow

      echo "Done. Open Screen Orientation Control on the TV if the service isn't running."
    '';
  };

  sharedPackages = with pkgs; [
    android-tools # Android SDK platform tools (adb, fastboot)
    arping # ARP broadcast utility (may need sudo/capabilities for raw-socket access to actually send ARP requests)
    bandwhich # CLI utility for displaying current network utilization
    dig # DNS lookup client
    #evebox # Web Based Event Viewer (GUI) for Suricata EVE Events in Elastic Search (meta.broken on darwin) FIXME
    iperf3 # Tool to measure IP bandwidth using UDP or TCP
    jq # Lightweight and flexible command-line JSON processor
    miniupnpc # Client that implements the UPnP Internet Gateway Device (IGD) specification
    #ntopng # High-speed web-based traffic analysis and flow collection tool (libcap input is Linux-only, not buildable on darwin) FIXME
    openhue-cli # CLI for interacting with Philips Hue smart lighting systems
    sane-backends # Scanner Access Now Easy backends, for network/eSCL scanner testing
    socat # Bidirectional socket relay
    speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    tcpdump # Network sniffer
    trippy # Network diagnostic tool
    tvPortrait # Reapplies portrait-mode settings on the Xiaomi TV Box S after reboot
    unifly # Elegant UniFi network management CLI & TUI - for humans and agents
    wireshark # Network protocol analyzer (GUI plus tshark and dumpcap)
    wol # Implements Wake On LAN functionality in a small program
    yq # Command-line YAML/XML/TOML processor - jq wrapper for YAML, XML, TOML documents
  ];
in
delib.module {
  name = "krit.services.network-tools";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    users.users.${myconfig.constants.user}.extraGroups = [ "wireshark" ];

    environment.systemPackages = sharedPackages ++ (with pkgs; [
      # Linux-only
      ethtool # Utility for controlling network drivers and hardware
      evebox # Web Based Event Viewer (GUI) for Suricata EVE Events in Elastic Search
      iw # Tool to use nl80211
      netcat-openbsd # Modern netcat implementation (nc)
      ntopng # High-speed web-based traffic analysis and flow collection tool
      ptcpdump # Process-aware, eBPF-based tcpdump
      rsyslog # Enhanced syslog implementation
      sane-airscan # Only provides the airscan-discover CLI; the SANE backend is not loaded (eSCL is covered by the built-in escl backend of sane-backends)
      suricata # Free and open source, mature, fast and robust network threat detection engine
      traceroute # Route tracing utility
      wavemon # Ncurses-based monitoring application for wireless network devices
      wirelesstools # Legacy wireless tools (iwconfig/iwlist), complements iw
    ]);
  };

  darwin.ifEnabled = {
    environment.systemPackages = sharedPackages;
  };

  home.ifEnabled = {
    home.packages = lib.optionals (moduleSystem == "home") [ pkgs.wol ];
    home.shellAliases = {
      wol-nas = "wol -i 192.168.1.255 6c:1f:f7:40:1e:d6";
    };
  };
}
