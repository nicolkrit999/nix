{
  pkgs,
  pkgs-unstable,
  lib,
  vars,
  ...
}:

{
  home.packages =
    (with pkgs; [

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      winboat # Enable to run windows programs

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

  programs.zsh = {
    enable = true;
    initExtra = ''
      # =======================================================
      # 🛡️ NAS SAFETY CORE
      # =======================================================
      # This reusable function checks arguments for NAS paths.
      # Returns 0 (Success) if safe.
      # Returns 1 (Error) if unsafe target found.
      function _nas_guard() {
        local NAS_PATH="/mnt/nicol_nas"
        local FORBIDDEN=false

        # 1. Check Current Directory
        if [[ "$PWD" == "$NAS_PATH"* ]]; then
          FORBIDDEN=true
        fi

        # 2. Check Arguments
        if [ "$FORBIDDEN" = false ]; then
          for arg in "$@"; do
            # Skip flags like -rf, -v
            if [[ "$arg" == -* ]]; then continue; fi
            
            local ABS_PATH
            ABS_PATH=$(realpath -m "$arg")
            
            if [[ "$ABS_PATH" == "$NAS_PATH"* ]]; then
              FORBIDDEN=true
              break
            fi
          done
        fi

        # 3. Verdict
        if [ "$FORBIDDEN" = true ]; then
          echo "⛔ SAFETY BLOCK: Deletion on NAS is disabled in this terminal."
          echo "   Target: $NAS_PATH"
          echo "   -------------------------------------------------------------"
          echo "   To DELETE: Use your File Manager (with forced delete) or SSH."
          echo "   To FORCE:  Run 'sudo -i' first to become root explicitly."
          return 1
        fi
        return 0
      }

      # 1. Intercept standard 'rm'
      function rm() {
        if _nas_guard "$@"; then
          command rm "$@"
        fi
      }

      # 2. Intercept 'sudo'
      function sudo() {
        # Check if the user is trying to run 'rm' with sudo
        if [[ "$1" == "rm" ]]; then
          # Shift arguments to remove "rm" so _nas_guard sees only flags/files
          local cmd="$1"
          shift
          
          # Run the check on the files
          if _nas_guard "$@"; then
            command sudo "$cmd" "$@"
          fi
        else
          # Pass any other command straight to real sudo
          command sudo "$@"
        fi
      }
    '';
  };

  # 5. Create/remove host-specific directories
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';
  };
}
