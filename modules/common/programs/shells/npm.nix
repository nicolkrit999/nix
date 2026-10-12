{ delib
, pkgs
, lib
, inputs
, ...
}:
delib.module {
  name = "programs.npm";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      packages = description (listOfOption str [ ]) "Global npm packages installed imperatively at activation: a deliberate, unpinned escape hatch.";
      hostPackages = listOfOption package [ ];
    };

  home.ifEnabled = { cfg, ... }: {
    home = {
      packages = [ pkgs.nodejs_latest ] ++ cfg.hostPackages;

      file.".npmrc".text = ''
        prefix = ''${HOME}/.npm-global
      '';

      sessionPath = [ "$HOME/.npm-global/bin" ];

      activation = lib.optionalAttrs (cfg.packages != [ ]) {
        npmGlobalPackages = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          stamp="''${XDG_STATE_HOME:-$HOME/.local/state}/npm-global-packages.stamp"
          want="${builtins.hashString "sha256" (pkgs.nodejs_latest.outPath + lib.concatStringsSep " " cfg.packages)}"
          installed=1
          for pkg in ${lib.concatStringsSep " " cfg.packages}; do
            case "$pkg" in
              @*) rest="''${pkg#@}"; name="@''${rest%%@*}" ;;
              *) name="''${pkg%%@*}" ;;
            esac
            [ -d "$HOME/.npm-global/lib/node_modules/$name" ] || installed=0
          done
          if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ] || [ "$installed" = 0 ]; then
            if run env PATH="${pkgs.nodejs_latest}/bin:$PATH" ${pkgs.nodejs_latest}/bin/npm install -g ${lib.concatStringsSep " " cfg.packages}; then
              if [ -z "''${DRY_RUN:-}" ]; then
                mkdir -p "$(dirname "$stamp")"
                printf '%s' "$want" > "$stamp"
              fi
            else
              echo "npm global install failed; will retry next activation" >&2
            fi
          fi
        '';
      };
    };
  };
}
