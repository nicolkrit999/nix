{ pkgs
, pkgs-unstable
, lib
, vars
, ...
}:

{
  imports = [
    # Common home-manager krit modules
    ../../common/krit/modules/home-manager

    # use-cases home-manager modules
    ../../common/krit/modules/use-cases/home-imports.nix

    # Architecture specific home-packages
    ../../common/krit/packages/default.nix

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
}
