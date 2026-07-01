{ delib, pkgs, ... }:
let
  snapCreate = pkgs.writeShellScriptBin "_snap-create" ''
    config_name="$1"
    read -p "📝 Enter snapshot description: " description
    if [ -z "$description" ]; then
      echo "❌ Description cannot be empty."
      exit 1
    fi
    read -p "🔒 Lock this snapshot (keep forever)? [y/N]: " lock_ans
    cleanup_flag="-c timeline"
    lock_status="UNLOCKED (will auto-delete)"
    if [[ "$lock_ans" =~ ^[Yy]$ ]]; then
      cleanup_flag=""
      lock_status="LOCKED (safe forever)"
    fi
    echo "🚀 Creating $lock_status snapshot for '$config_name'..."
    sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
  '';

  snapLock = pkgs.writeShellScriptBin "snap-lock" ''
    echo "Which config? (1=home, 2=root)"
    read -p "Selection: " k
    if [ "$k" = "2" ]; then CFG="root"; else CFG="home"; fi
    sudo snapper -c "$CFG" list
    echo ""
    read -p "Enter Snapshot ID to LOCK: " ID
    if [ -n "$ID" ]; then
      sudo snapper -c "$CFG" modify -c "" "$ID"
      echo "✅ Snapshot #$ID in '$CFG' is now LOCKED."
    fi
  '';

  snapUnlock = pkgs.writeShellScriptBin "snap-unlock" ''
    echo "Which config? (1=home, 2=root)"
    read -p "Selection: " k
    if [ "$k" = "2" ]; then CFG="root"; else CFG="home"; fi
    sudo snapper -c "$CFG" list
    echo ""
    read -p "Enter Snapshot ID to UNLOCK: " ID
    if [ -n "$ID" ]; then
      sudo snapper -c "$CFG" modify -c "timeline" "$ID"
      echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED."
    fi
  '';

  snapCreateHome = pkgs.writeShellScriptBin "snap-create-home" ''
    exec ${snapCreate}/bin/_snap-create home
  '';

  snapCreateRoot = pkgs.writeShellScriptBin "snap-create-root" ''
    exec ${snapCreate}/bin/_snap-create root
  '';
in
delib.module {
  name = "services.snapshots";

  home.ifEnabled = {
    home.packages = [
      snapLock
      snapUnlock
      snapCreateHome
      snapCreateRoot
    ];
  };
}
