{ delib, pkgs, lib, moduleSystem, ... }:
delib.module {
  name = "services.tailscale";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "bash";

      posixHelpers = ''
        # TAILSCALE EXIT-NODE HELPERS
        tailscalenodeset() {
          local node
          node=$(tailscale exit-node suggest | grep -oE -m1 'exit-node=[^`[:space:]]+' | sed 's/^exit-node=//')
          tailscale set --exit-node="$node" --exit-node-allow-lan-access=true
        }

        tailscalenoderemove() {
          tailscale set --exit-node=
        }
      '';

      trayscaleNeeded =
        moduleSystem == "nixos"
        && (
          (myconfig.programs.hyprland.enable or false)
          || (myconfig.programs.niri.enable or false)
          || (myconfig.programs.mango.enable or false)
        );
    in
    {
      programs.zsh.initContent = lib.mkIf (currentShell == "zsh") (lib.mkAfter posixHelpers);
      programs.bash.initExtra = lib.mkIf (currentShell == "bash") (lib.mkAfter posixHelpers);

      programs.fish.functions = lib.mkIf (currentShell == "fish") {
        tailscalenodeset = ''
          tailscale set --exit-node=(tailscale exit-node suggest | string match -r -g 'exit-node=([^`\s]+)') --exit-node-allow-lan-access=true
        '';
        tailscalenoderemove = ''
          tailscale set --exit-node=
        '';
      };

      home.packages = lib.optional trayscaleNeeded pkgs.trayscale;
    };

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      services.tailscale = {
        enable = true;
        # Equivalent of running `sudo tailscale set --operator=$USER` once by
        # hand: lets the configured user run `tailscale up`/`set` without sudo.
        extraSetFlags = [ "--operator=${myconfig.constants.user}" ];
      };

      networking.firewall = {
        allowedUDPPorts = [ 41641 ];
        trustedInterfaces = [ "tailscale0" ];
        checkReversePath = "loose";
      };

      systemd.services.tailscale-autoconnect = {
        description = "Retry `tailscale up` until network is actually ready";
        after = [
          "network-online.target"
          "NetworkManager-wait-online.service"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          for i in $(seq 1 20); do
            if ${pkgs.tailscale}/bin/tailscale up; then
              exit 0
            fi
            sleep 15
          done
          echo "tailscale-autoconnect: giving up after repeated failures" >&2
          exit 1
        '';
      };
    };

  darwin.ifEnabled = {
    services.tailscale.enable = true;
  };
}
