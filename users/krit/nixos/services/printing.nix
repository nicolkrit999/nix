{ delib, lib, pkgs, ... }:
delib.module {
  name = "krit.services.printing";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      # Name of the printer made the default once its queue exists. Empty keeps CUPS' own choice.
      defaultPrinter = strOption "";
      # Queue chosen as default while fallbackProbeHost:fallbackProbePort answers (e.g. a school printer);
      # the printer being off never matters. Non-empty switches the default from "set once at queue
      # creation" to "re-picked on network events".
      fallbackPrinter = strOption "";
      fallbackProbeHost = strOption "";
      fallbackProbePort = intOption 445;
      printers = listOfOption
        (submodule {
          options = {
            name = strOption "";
            description = strOption "";
            # No default on purpose: an unmapped printer must fail the assertion.
            address = strOption "";
            # Multifunction device: also expose its eSCL (driverless) scanner to SANE / simple-scan.
            scanner = boolOption false;
            ppdOptions = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
          };
        }) [ ];
    };

  # simple-scan defaults: the highest quality the HP offers (1200 dpi flatbed, JPEG quality 100), text
  # documents on A4, both sides. Paper sizes are in tenths of a mm. The ADF tops out lower than the
  # flatbed, so ADF scans use the closest resolution the device accepts.
  home.ifEnabled =
    { cfg, ... }:
    lib.mkIf (lib.any (p: p.scanner) cfg.printers) {
      dconf.settings."org/gnome/SimpleScan" = {
        text-dpi = 1200;
        photo-dpi = 1200;
        jpeg-quality = 100;
        document-type = "text";
        paper-width = 2100;
        paper-height = 2970;
        page-side = "both";
        save-format = "application/pdf";
      };
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      cupsPkg = pkgs.cups;
      scanners = lib.filter (p: p.scanner) cfg.printers;
      # Merged into the stock escl.conf by mkSaneConfig. Static device lines instead of mDNS discovery,
      # so scanning works without avahi (the printer sits on a fixed address, like the print queue).
      esclConf = pkgs.writeTextFile {
        name = "krit-escl-conf";
        destination = "/etc/sane.d/escl.conf";
        text = lib.concatMapStrings (p: "device https://${p.address}:443 \"${p.description}\"\n") scanners;
      };
      printerBlock = p: ''
        register ${lib.escapeShellArg p.name} ${lib.escapeShellArg p.address} ${lib.escapeShellArg p.description} \
          ${lib.escapeShellArgs (lib.mapAttrsToList (k: v: "${k}=${v}") p.ppdOptions)}
      '';
      script = pkgs.writeShellScript "krit-printers" ''
        export PATH=${lib.makeBinPath [ cupsPkg pkgs.coreutils pkgs.bash ]}
        default=${lib.escapeShellArg cfg.defaultPrinter}
        fallback=${lib.escapeShellArg cfg.fallbackPrinter}

        register() {
          name=$1; addr=$2; desc=$3; shift 3
          if ! timeout 3 bash -c "exec 3<>/dev/tcp/$addr/631" 2>/dev/null; then
            echo "$name ($addr) unreachable, skipping"
            return 0
          fi
          existed=0
          lpstat -v "$name" >/dev/null 2>&1 && existed=1
          opts=()
          for o in "$@"; do opts+=(-o "$o"); done
          if timeout 60 lpadmin -p "$name" -E -v "ipp://$addr/ipp/print" -m everywhere \
              -D "$desc" -o printer-is-shared=false "''${opts[@]}"; then
            if [ "$existed" = 0 ] && [ "$name" = "$default" ] && [ -z "$fallback" ]; then
              lpadmin -d "$name" || true
            fi
          else
            echo "lpadmin failed for $name, will retry"
          fi
        }

        ${lib.concatMapStrings printerBlock cfg.printers}
        exit 0
      '';
      pickDefault = pkgs.writeShellScript "krit-printer-default" ''
        export PATH=${lib.makeBinPath [ cupsPkg pkgs.coreutils pkgs.bash ]}
        home=${lib.escapeShellArg cfg.defaultPrinter}
        away=${lib.escapeShellArg cfg.fallbackPrinter}
        want=$home
        # DNS lookup and connect both happen inside this one 2 s bound; any failure keeps the home printer.
        if timeout -k 1 2 bash -c "exec 3<>/dev/tcp/${cfg.fallbackProbeHost}/${toString cfg.fallbackProbePort}" 2>/dev/null; then
          want=$away
        fi
        lpstat -p "$want" >/dev/null 2>&1 || want=$home
        lpstat -p "$want" >/dev/null 2>&1 || exit 0
        [ "$(lpstat -d 2>/dev/null)" = "system default destination: $want" ] && exit 0
        if lpadmin -d "$want"; then
          echo "default printer -> $want"
        elif [ "$want" != "$home" ] && lpadmin -d "$home"; then
          echo "default printer -> $home (fallback)"
        fi
        exit 0
      '';
    in
    {
      assertions =
        [
          {
            assertion = cfg.fallbackPrinter == "" || (cfg.defaultPrinter != "" && cfg.fallbackProbeHost != "");
            message = "krit.services.printing.fallbackPrinter needs defaultPrinter and fallbackProbeHost to be set.";
          }
          {
            assertion = cfg.printers != [ ];
            message = ''
              krit.services.printing is enabled on host "${myconfig.constants.hostname}", but
              krit.services.printing.printers is empty.
            '';
          }
          {
            assertion = cfg.defaultPrinter == "" || builtins.elem cfg.defaultPrinter (map (p: p.name) cfg.printers);
            message = "krit.services.printing.defaultPrinter must name an entry of krit.services.printing.printers.";
          }
        ]
        ++ map
          (p: {
            assertion = p.name != "" && p.address != "";
            message = ''
              krit.services.printing on host "${myconfig.constants.hostname}": every printer needs a
              name and an address (got name="${p.name}", address="${p.address}").
            '';
          })
          cfg.printers;

      hardware.sane = lib.mkIf (scanners != [ ]) {
        enable = true;
        extraBackends = [ esclConf ];
      };
      environment.systemPackages = lib.optional (scanners != [ ]) pkgs.simple-scan;

      services.printing = {
        enable = true;
        browsed.enable = false;
      };

      # hardware.printers.ensurePrinters is not used: it runs lpadmin -m everywhere in
      # cups.service postStart under set -e, so an unreachable printer fails cups.service itself.
      systemd.services.krit-printers = {
        description = "Register driverless IPP printer queues";
        after = [ "cups.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ script ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = script;
          TimeoutStartSec = "3min";
        };
      };
      systemd.services.krit-printer-default = lib.mkIf (cfg.fallbackPrinter != "") {
        description = "Pick the default printer by school-side reachability";
        after = [ "krit-printers.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pickDefault;
          TimeoutStartSec = "15s";
        };
      };
      systemd.services.krit-printers.serviceConfig.ExecStartPost =
        lib.mkIf (cfg.fallbackPrinter != "") "-${pkgs.systemd}/bin/systemctl start --no-block krit-printer-default.service";
      # Event-driven only (no timer, no Restart=): a queue is (re)registered, and the default re-picked,
      # once per NetworkManager up / connectivity-change event. Down and connectivity NONE are ignored.
      networking.networkmanager.dispatcherScripts = [{
        type = "basic";
        source = pkgs.writeShellScript "krit-printers-dispatch" ''
          [ "$1" = lo ] && exit 0
          case "$2" in
            up) ;;
            connectivity-change) [ "$CONNECTIVITY_STATE" = NONE ] && exit 0 ;;
            *) exit 0 ;;
          esac
          # Keep the printers reachable while a Tailscale exit node (e.g. Mullvad) is active: the exit node
          # puts a default route in table 52 (rule 5270) and --exit-node-allow-lan-access only exempts the
          # directly attached subnet, but the printers sit on another VLAN behind the router. A rule ahead of
          # Tailscale's (5270) sends them through the main table (the LAN gateway). Idempotent, /32 only.
          ${lib.concatMapStrings (p: ''
            ${pkgs.iproute2}/bin/ip rule del to ${p.address}/32 lookup main priority 5100 2>/dev/null || true
            ${pkgs.iproute2}/bin/ip rule add to ${p.address}/32 lookup main priority 5100 || true
          '') cfg.printers}
          ${pkgs.systemd}/bin/systemctl start --no-block krit-printers.service || true
          exit 0
        '';
      }];
    };
}
