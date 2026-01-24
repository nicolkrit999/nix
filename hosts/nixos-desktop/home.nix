{
  pkgs,
  pkgs-unstable,
  lib,
  vars,
  ...
}:
let
  policyRoot = "/home/${vars.user}/.librewolf-policyroot";
in
{
  imports = [
    # Common home-manager krit modules
    ../../common/krit/modules/home-manager

    # use-cases home-manager modules
    ../../common/krit/modules/use-cases/home-imports.nix

    # Local Host Modules
    ./optional/general-hm-modules
    ./optional/host-hm-modules
  ];

  home.packages =
    (with pkgs; [

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      brave # Needed for pwa to work
      winboat # Enable to run windows programs
      librewolf

      (pkgs.writeShellScriptBin "librewolf" ''
        set -eu
        echo "WRAPPER IS RUNNING" >&2
        echo "MOZ_APP_DISTRIBUTION=${policyRoot}" >&2

        export MOZ_APP_DISTRIBUTION="${policyRoot}"

        if [ ! -f "${policyRoot}/distribution/policies.json" ]; then
            echo "MISSING ${policyRoot}/distribution/policies.json" >&2
            exit 123
        fi

        exec ${pkgs.librewolf}/bin/librewolf "$@"
      '')

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
    ])

    ++ (with pkgs-unstable; [ ]);

  # 📂 XDG OVERRIDES
  # Disable folders I don't use
  xdg.userDirs = {
    publicShare = null;
    music = null;
  };

  home.sessionVariables = { };

  #FIXME: Currently not working (ignored)
  /*
    programs.zsh = {
    enable = true;
    initExtra = ''
      # -------------------------------------------------------
      # 🛡️ NAS SAFETY CORE
      # -------------------------------------------------------

      unalias rm 2>/dev/null || true

      # Returns 0 (True) if the operation targets the NAS.
      function _is_nas_target() {
        local NAS_PATH="/mnt/nicol_nas"

        # 1. Check Current Directory
        if [[ "$PWD" == "$NAS_PATH"* ]]; then
          return 0
        fi

        # 2. Check Arguments
        for arg in "$@"; do
          # Skip flags like -rf, -v
          if [[ "$arg" == -* ]]; then continue; fi

          # Resolve path
          local ABS_PATH
          ABS_PATH=$(realpath -m "$arg")

          if [[ "$ABS_PATH" == "$NAS_PATH"* ]]; then
            return 0
          fi
        done
        return 1
      }

      # 1. Intercept standard 'rm'
      function rm() {
        if _is_nas_target "$@"; then
          echo "⚠️  NAS DETECTED: Forcing Interactive Mode (rm -i)"
          command rm "$@" -i
        else
          # Run normally
          command rm "$@"
        fi
      }

      # 2. Intercept 'sudo'
      function sudo() {
        if [[ "$1" == "rm" ]]; then
          local cmd="$1"
          shift # Remove "rm" from args

          if _is_nas_target "$@"; then
             echo "⚠️  NAS DETECTED (Sudo): Forcing Interactive Mode (rm -i)"
             command sudo rm "$@" -i
          else
             command sudo rm "$@"
          fi
        else
          # Pass any other command straight to real sudo
          command sudo "$@"
        fi
      }
    '';
    };
  */

  # 5. Create/remove host-specific directories
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';

  };

  home.file.".librewolf-policyroot/distribution/policies.json".text = builtins.toJSON {
    policies = {
      SupportMenu = {
        Title = "HM POLICY ACTIVE";
        URL = "https://example.com";
      };
    };
  };
}
