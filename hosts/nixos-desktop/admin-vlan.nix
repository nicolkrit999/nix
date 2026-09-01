{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.desktop.admin-vlan";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { ... }:
    {
      networking.networkmanager.ensureProfiles.profiles."admin-vlan" = {
        connection = {
          id = "admin-vlan";
          type = "vlan";
          interface-name = "admin-vlan";
          autoconnect = false; # critical: never auto-joins
        };
        vlan = {
          id = 40;
          parent = "enp8s0";
        };
        ipv4 = {
          method = "auto";
          never-default = true; # SAFETY: prevent Admin VLAN's DHCP gateway from becoming/racing the default route - desktop's general internet traffic must keep transiting Trusted, not Admin
          # UniFi gateway console (192.168.1.1) sits on the same subnet as the
          # normal Trusted network (192.168.1.0/24), so the directly-connected
          # route via Trusted always wins over admin-vlan's own connected route
          # to 192.168.40.0/24 - never-default only suppresses the *default*
          # route, it does nothing for this same-subnet case. Force traffic to
          # the gateway console specifically via admin-vlan's own gateway.
          route1 = "192.168.1.1/32,192.168.40.1";
        };
        ipv6.method = "disabled";
      };
    };

  home.ifEnabled =
    { ... }:
    let
      adminVlanOn = pkgs.writeShellScriptBin "admin-vlan-on" ''
        set -euo pipefail
        ADMIN_HOST="192.168.1.1"

        ${pkgs.networkmanager}/bin/nmcli connection up admin-vlan
        if ! ${pkgs.iproute2}/bin/ip -4 addr show admin-vlan | ${pkgs.gnugrep}/bin/grep -q "inet "; then
          echo "❌ Failed to join admin-vlan"
          exit 1
        fi
        echo "✅ Joined admin-vlan ($(${pkgs.networkmanager}/bin/nmcli -g IP4.ADDRESS connection show admin-vlan))"

        # Poll up to ~5s instead of a fixed sleep, since nmcli can return before the
        # route/DHCP lease is actually usable.
        reachable=false
        for _ in $(seq 1 10); do
          if ${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 2 -k "https://$ADMIN_HOST" \
              | ${pkgs.gnugrep}/bin/grep -qE "^[23]"; then
            reachable=true
            break
          fi
          sleep 0.5
        done

        if [ "$reachable" = true ]; then
          echo "✅ Admin interface reachable ($ADMIN_HOST)"
        else
          echo "❌ Admin interface NOT reachable ($ADMIN_HOST) - check VLAN/routing"
        fi
      '';

      adminVlanOff = pkgs.writeShellScriptBin "admin-vlan-off" ''
        set -euo pipefail
        ADMIN_HOST="192.168.1.1"

        ${pkgs.networkmanager}/bin/nmcli connection down admin-vlan
        if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show --active | ${pkgs.gnugrep}/bin/grep -qx admin-vlan; then
          echo "❌ Failed to leave admin-vlan"
          exit 1
        fi
        echo "✅ Left admin-vlan"

        unreachable=false
        for _ in $(seq 1 10); do
          if ! ${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 2 -k "https://$ADMIN_HOST" \
              | ${pkgs.gnugrep}/bin/grep -qE "^[23]"; then
            unreachable=true
            break
          fi
          sleep 0.5
        done

        if [ "$unreachable" = true ]; then
          echo "✅ Admin interface correctly unreachable ($ADMIN_HOST)"
        else
          echo "❌ Admin interface still reachable ($ADMIN_HOST) - isolation leak!"
        fi
      '';
    in
    {
      home.packages = [
        adminVlanOn
        adminVlanOff
      ];
    };
}
