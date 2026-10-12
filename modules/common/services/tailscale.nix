{ delib, pkgs, lib, config, moduleSystem, ... }:
delib.module {
  name = "services.tailscale";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell;

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
          myconfig.programs.hyprland.enable
          || myconfig.programs.niri.enable
          || myconfig.programs.mango.enable
        );
    in
    {
      programs = {
        zsh.initContent = lib.mkIf (currentShell == "zsh") (lib.mkAfter posixHelpers);
        bash.initExtra = lib.mkIf (currentShell == "bash") (lib.mkAfter posixHelpers);

        fish.functions = lib.mkIf (currentShell == "fish") {
          tailscalenodeset = ''
            tailscale set --exit-node=(tailscale exit-node suggest | string match -r -g 'exit-node=([^`\s]+)') --exit-node-allow-lan-access=true
          '';
          tailscalenoderemove = ''
            tailscale set --exit-node=
          '';
        };
      };

      home.packages = lib.optional trayscaleNeeded pkgs.trayscale;
    };

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "client";
        # Equivalent of running `sudo tailscale set --operator=$USER` once by
        # hand: lets the configured user run `tailscale up`/`set` without sudo.
        extraSetFlags = [ "--operator=${myconfig.constants.user}" ];
        # Only nixpkgs' tailscaled-autoconnect (present because service-wiring.nix sets
        # authKeyFile) uses these, and only in NeedsLogin/NeedsMachineAuth/Stopped. --reset is
        # needed there: `up` refuses to run unless every non-default pref is restated.
        extraUpFlags = [
          "--reset"
          "--exit-node-allow-lan-access"
          "--operator=${myconfig.constants.user}"
        ];
      };

      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };

  darwin.ifEnabled =
    let
      caskName = c: if builtins.isString c then c else c.name;
    in
    {
      services.tailscale.enable = true;

      assertions = [
        {
          assertion = !(builtins.elem "tailscale-app" (map caskName config.homebrew.casks));
          message = "myconfig.services.tailscale runs the nix-darwin tailscaled daemon, but the Homebrew cask \"tailscale-app\" is also installed. Tailscale supports only one macOS variant per machine: drop the cask or disable myconfig.services.tailscale.";
        }
      ];
    };
}
