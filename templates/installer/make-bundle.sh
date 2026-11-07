#!/usr/bin/env bash
# Builds the encrypted clone bundle on an ORIGINAL machine.
#
# Contents (tar, then `age -p` passphrase encryption):
#   host/ssh_host_ed25519_key, host/ssh_host_ed25519_key.pub, user/keys.txt, meta.txt
# No sbctl keys: the clone creates its own.
#
# Usage: make-bundle.sh --host nixos-desktop|nixos-laptop [--host-key PATH] [--user-key PATH]
#                       [--out-dir DIR] [--force]
#   defaults: --host-key /persist/etc/ssh/ssh_host_ed25519_key
#             --user-key ~/.config/sops/age/keys.txt   (of the invoking user, also under sudo)
#             --out-dir  .
#
# The keys are only ever staged on a tmpfs and are piped into age; the only file written to a
# disk is the encrypted result. age -p asks for a passphrase (type your own, confirmed by typing it twice,
# or press Enter for a blank entry to make age generate one and print it once).
set -euo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

HOST=""
HOST_KEY=/persist/etc/ssh/ssh_host_ed25519_key
USER_KEY=""
OUT_DIR=.
FORCE=0

if [[ -n ${SUDO_USER:-} && $EUID -eq 0 ]]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  user_home=$HOME
fi
USER_KEY=$user_home/.config/sops/age/keys.txt

while (($#)); do
  case $1 in
    --host) HOST=${2:?--host needs a value}; shift ;;
    --host-key) HOST_KEY=${2:?}; shift ;;
    --user-key) USER_KEY=${2:?}; shift ;;
    --out-dir) OUT_DIR=${2:?}; shift ;;
    --force) FORCE=1 ;;
    -h | --help) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

case $HOST in
  nixos-desktop | nixos-laptop) ;;
  *) die "--host must be nixos-desktop or nixos-laptop" ;;
esac

for t in age tar; do
  command -v "$t" >/dev/null 2>&1 || die "$t not found in PATH"
done

# The host key is root-only: elevate once, keeping the already-resolved absolute paths.
if [[ ! -r $HOST_KEY && $EUID -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || die "$HOST_KEY is not readable and sudo is missing"
  sudo_args=(--host "$HOST" --host-key "$HOST_KEY" --user-key "$USER_KEY" --out-dir "$(cd "$OUT_DIR" && pwd)")
  ((FORCE)) && sudo_args+=(--force)
  # keep the caller PATH: sudo would reset it and lose age/tar when run through a nix wrapper
  exec sudo env "PATH=$PATH" "$0" "${sudo_args[@]}"
fi

[[ -r $HOST_KEY ]] || die "host key not readable: $HOST_KEY"
[[ -r ${HOST_KEY}.pub ]] || die "host public key not readable: ${HOST_KEY}.pub"
[[ -r $USER_KEY ]] || die "user age key not readable: $USER_KEY"
grep -q 'BEGIN OPENSSH PRIVATE KEY' "$HOST_KEY" || die "$HOST_KEY does not look like an OpenSSH private key"
grep -q 'AGE-SECRET-KEY-' "$USER_KEY" || die "$USER_KEY does not contain an age secret key"
[[ -d $OUT_DIR ]] || die "output directory does not exist: $OUT_DIR"

OUT=$OUT_DIR/$HOST-clone-bundle.tar.age
if [[ -e $OUT && $FORCE -eq 0 ]]; then
  die "$OUT exists (use --force to overwrite)"
fi

# Stage on tmpfs only. /dev/shm is the fallback if XDG_RUNTIME_DIR is missing.
base=${XDG_RUNTIME_DIR:-/dev/shm}
[[ -d $base && -w $base ]] || base=/dev/shm
case $(findmnt -no FSTYPE -T "$base" 2>/dev/null || stat -f -c %T "$base") in
  tmpfs | ramfs) ;;
  *) die "$base is not on tmpfs; refusing to stage unencrypted keys" ;;
esac
STAGE=$(mktemp -d "$base/clone-bundle.XXXXXX")
cleanup() {
  if [[ -d $STAGE ]]; then
    find "$STAGE" -type f -exec shred -u {} + 2>/dev/null || true
    rm -rf "$STAGE"
  fi
  if [[ -n ${TMP_OUT:-} && -e $TMP_OUT ]]; then
    rm -f "$TMP_OUT"
  fi
}
trap cleanup EXIT
umask 077
mkdir "$STAGE/host" "$STAGE/user"
cp -- "$HOST_KEY" "$STAGE/host/ssh_host_ed25519_key"
cp -- "${HOST_KEY}.pub" "$STAGE/host/ssh_host_ed25519_key.pub"
cp -- "$USER_KEY" "$STAGE/user/keys.txt"
printf 'format=1\nhost=%s\ncreated=%s\n' "$HOST" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$STAGE/meta.txt"

TMP_OUT=$OUT.partial
rm -f "$TMP_OUT"
cat >&2 <<'MSG'
Encrypting the bundle with a passphrase. Either:
  - type your own passphrase (age asks for it twice to confirm), or
  - press Enter on the first prompt to let age generate one; age prints it once, copy it then.
Store the passphrase in your password manager, NOT on the stick.
MSG
tar -C "$STAGE" --owner=0 --group=0 --numeric-owner -cf - host user meta.txt | age -p -o "$TMP_OUT"

# The result must be an age file, never a tar.
head -c 21 "$TMP_OUT" | grep -q '^age-encryption.org/v1' || die "output is not an age file; removed"
chmod 600 "$TMP_OUT"
mv -f "$TMP_OUT" "$OUT"
TMP_OUT=""

cat <<EOF

Bundle written: $OUT

Where to put it:
  - on the Ventoy USB stick, next to the NixOS ISO (the installer scans every attached stick for *.age)
  - a backup copy on the NAS, in the installer-iso folder
  - keep the passphrase separate from the stick

Check it later without extracting to disk:  age -d '$OUT' | tar -tf -
EOF
