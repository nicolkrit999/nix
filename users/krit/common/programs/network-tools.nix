{ delib, pkgs, inputs, ... }:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Darwin-compatible network tools
  sharedPackages = (with pkgs; [
    wireshark # Powerful network protocol analyzer
    tshark # Powerful network protocol analyzer
    tcpdump # Network sniffer
    jq # Lightweight and flexible command-line JSON processor
    yq # Command-line YAML/XML/TOML processor - jq wrapper for YAML, XML, TOML documents
    wol # Implements Wake On LAN functionality in a small program
    miniupnpc # Client that implements the UPnP Internet Gateway Device (IGD) specification
    trippy # Network diagnostic tool
    speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    bandwhich # CLI utility for displaying current network utilization
    openhue-cli # CLI for interacting with Philips Hue smart lighting systems
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
      rsyslog # Enhanced syslog implementation
      ntopng # High-speed web-based traffic analysis and flow collection tool
      suricata # Free and open source, mature, fast and robust network threat detection engine
      evebox # Web Based Event Viewer (GUI) for Suricata EVE Events in Elastic Search
      ptcpdump # Process-aware, eBPF-based tcpdump
      wavemon # Ncurses-based monitoring application for wireless network devices
      iw # Tool to use nl80211
      iperf3 # Tool to measure IP bandwidth using UDP or TCP
    ]);
  };

  darwin.ifEnabled = {
    environment.systemPackages = sharedPackages;
  };
}
