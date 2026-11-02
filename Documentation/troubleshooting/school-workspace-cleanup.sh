#!/usr/bin/env bash
# Guarded removal of the OLD ~/.school-workspace (pre krit-school).
# Run it yourself, as the normal user `krit`, after krit-school works.
# Dry run by default; pass --really to delete.
#
# Safety rules (the tree held davfs/rclone mountpoints, deleting through a live
# mount would delete remote data):
#  1. refuses to run if ANYTHING is mounted at or below the tree,
#  2. refuses if the path is a symlink or not under $HOME,
#  3. never uses rm -r across filesystems (--one-file-system),
#  4. refuses if a mountpoint-like dir still contains files (stale FUSE).
set -euo pipefail

TARGET="${HOME}/.school-workspace"
REALLY=0
[ "${1:-}" = "--really" ] && REALLY=1

[ -e "$TARGET" ] || { echo "nothing to do: $TARGET does not exist"; exit 0; }
[ ! -L "$TARGET" ] || { echo "ABORT: $TARGET is a symlink"; exit 1; }
case "$(realpath -e "$TARGET")" in
  "$HOME"/*) ;;
  *) echo "ABORT: $TARGET resolves outside \$HOME"; exit 1 ;;
esac

if findmnt -rn -R "$TARGET" | grep -q .; then
  echo "ABORT: mounts found at or below $TARGET:"
  findmnt -R "$TARGET"
  echo "Unmount them first (systemctl --user stop school-onedrive-mount; umount the davfs mounts)."
  exit 1
fi

# A dead FUSE mount shows up as 'Transport endpoint is not connected'.
if ! find "$TARGET" -xdev >/dev/null 2>"${TMPDIR:-/tmp}/school-cleanup.err"; then
  echo "ABORT: tree is not readable (stale FUSE mount?):"
  cat "${TMPDIR:-/tmp}/school-cleanup.err"
  exit 1
fi

echo "Contents of $TARGET (same filesystem only):"
du -xsh "$TARGET"
find "$TARGET" -xdev -maxdepth 2 | sort

if [ "$REALLY" -ne 1 ]; then
  echo
  echo "Dry run. Re-run with --really to delete."
  exit 0
fi

rm -rf --one-file-system -- "$TARGET"
echo "removed $TARGET"
