{ delib, pkgs, inputs, ... }:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Darwin-compatible network tools
  sharedPackages = (with pkgs; [
    bandwhich # CLI utility for displaying current network utilization
    #evebox # Web Based Event Viewer (GUI) for Suricata EVE Events in Elastic Search (compatible with darwin but currently broken) FIXME
    iperf3 # Tool to measure IP bandwidth using UDP or TCP
    jq # Lightweight and flexible command-line JSON processor
    miniupnpc # Client that implements the UPnP Internet Gateway Device (IGD) specification
    #ntopng # High-speed web-based traffic analysis and flow collection tool (compatible with darwin but currently broken due to libcap Linux-only dependency) FIXME
    openhue-cli # CLI for interacting with Philips Hue smart lighting systems
    speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    tcpdump # Network sniffer
    trippy # Network diagnostic tool
    tshark # Powerful network protocol analyzer
    wireshark # Powerful network protocol analyzer
    wol # Implements Wake On LAN functionality in a small program
    yq # Command-line YAML/XML/TOML processor - jq wrapper for YAML, XML, TOML documents
  ]) ++ (with pkgs-unstable; [
    unifly # Elegant UniFi network management CLI & TUI - for humans and agents
  ]);
in
delib.module {
  name = "krit.services.network-tools";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = sharedPackages ++ (with pkgs; [
      # Linux-only
      evebox # Web Based Event Viewer (GUI) for Suricata EVE Events in Elastic Search
      iw # Tool to use nl80211
      ntopng # High-speed web-based traffic analysis and flow collection tool
      ptcpdump # Process-aware, eBPF-based tcpdump
      rsyslog # Enhanced syslog implementation
      suricata # Free and open source, mature, fast and robust network threat detection engine
      wavemon # Ncurses-based monitoring application for wireless network devices
    ]);
  };

  darwin.ifEnabled = {
    environment.systemPackages = sharedPackages;
  };
}
