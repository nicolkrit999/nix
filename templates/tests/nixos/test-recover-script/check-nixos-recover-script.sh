#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

if ! compgen -G / >/dev/null 2>&1; then
  BASH_FULL=""
  for c in "${RECOVER_TEST_BASH:-}" /run/current-system/sw/bin/bash /usr/bin/bash /bin/bash; do
    [[ -n $c && -x $c ]] && "$c" -c 'compgen -G / >/dev/null' 2>/dev/null && { BASH_FULL=$c; break; }
  done
  if [[ -z $BASH_FULL ]]; then
    p=$(nix build --no-link --print-out-paths --inputs-from "$REPO_ROOT" nixpkgs#bashInteractive 2>/dev/null | head -n1)
    [[ -x $p/bin/bash ]] && BASH_FULL=$p/bin/bash
  fi
  [[ -n $BASH_FULL ]] || { echo "FAIL: no bash with the compgen builtin found (set RECOVER_TEST_BASH)"; exit 1; }
  exec "$BASH_FULL" "${BASH_SOURCE[0]}" "$@"
fi

source "$REPO_ROOT/templates/tests/lib/evidence.sh"
SCRIPT="${RECOVER_SCRIPT:-$REPO_ROOT/Documentation/troubleshooting/recover.sh}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

TW=$(mktemp -d "${TMPDIR:-/tmp}/recover-test.XXXXXXXX")
trap 'chmod -R u+w "$TW" 2>/dev/null; rm -rf "$TW"' EXIT
T=$TW/fx
mkdir -p "$T" "$TW/own-tmp"

pass() { printf "  %-72s ${GREEN}PASS${NC}\n" "$1"; ((PASS++)) || true; }
fail() { printf "  %-72s ${RED}FAIL${NC}\n" "$1"; ((FAIL++)) || true; FAILURES+=("$1: $2"); }
check() {
  if [[ $2 == "$3" ]]; then pass "$1"; else fail "$1" "expected [$2] got [$3]"; fi
}
differs() {
  if [[ $2 != "$3" ]]; then pass "$1"; else fail "$1" "both sides are [$2]"; fi
}

STUBS=$TW/stubs
STUB_LOG=$TW/stub-calls.log
STUB_DATA=$TW/stub-data
mkdir -p "$STUBS" "$STUB_DATA"
: >"$STUB_LOG"
export STUB_LOG STUB_DATA

mkstub() { # name body
  printf '#!%s\n%s\n' "$BASH" "$2" >"$STUBS/$1"
  chmod +x "$STUBS/$1"
}
for t in sbctl nix nixos-enter nixos-rebuild chroot umount cryptsetup systemctl sudo unshare; do
  mkstub "$t" 'echo "UNEXPECTED '"$t"' $*" >>"$STUB_LOG"; exit 99'
done
mkstub mount 'echo "MOUNT $*" >>"$STUB_LOG"'
mkstub findmnt 'cat "$STUB_DATA/findmnt" 2>/dev/null'
mkstub blkid 'cat "$STUB_DATA/blkid" 2>/dev/null'
mkstub lsblk 'cat "$STUB_DATA/lsblk" 2>/dev/null'
mkstub efibootmgr 'if [[ ${1:-} == -v ]]; then cat "$STUB_DATA/efibootmgr-v" 2>/dev/null; else echo "EFIBOOTMGR $*" >>"$STUB_LOG"; fi'
export PATH="$STUBS:$PATH"

tmp_before=$(find "$TW/own-tmp" -mindepth 1 | wc -l)
flags_before=$-
TMPDIR=$TW/own-tmp source "$SCRIPT"
echo -e "\n${BOLD}=== recover.sh: sourcing ===${NC}"
check "sourcing changes no shell flags" "$flags_before" "$-"
check "sourcing creates no temp dir" "$tmp_before" "$(find "$TW/own-tmp" -mindepth 1 | wc -l)"
declare -F main detect_bootloader_disk lanza_preflight >/dev/null
check "sourcing defines main + the helpers under test" 0 "$?"

read_gen_file() {
  local f=$1/var/nix/profiles/$2/$3
  [[ -f $f ]] || return 2
  printf '%s\n' "$(<"$f")"
}
WARN_LOG=$TW/warnings.log
warn() { echo "WARN: $*" >>"$WARN_LOG"; }
info() { :; }
ok() { :; }
EFIVARS_DIR=$TW/efivars
SYSFS_BLOCK=$TW/sysblock
export EFIVARS_DIR SYSFS_BLOCK

mkgen() { # root [sbctl-keydir]
  local r=$1 g=$1/nix/var/nix/profiles/system-3-link
  mkdir -p "$g/etc/sbctl"
  printf 'x / tmpfs\n' >"$g/etc/fstab"
  if [[ -n ${2:-} ]]; then
    printf '%%YAML 1.1\n---\nguid: %s/GUID\nkeydir: %s\n' "${2%/keys}" "$2" >"$g/etc/sbctl/sbctl.conf"
  else
    rmdir "$g/etc/sbctl"
  fi
  return 0
}
mkgrub() {
  mkdir -p "$1/boot/EFI/BOOT" "$1/boot/grub/x86_64-efi" "$1/boot/EFI/NixOS-boot"
  echo grub_mod_init >"$1/boot/EFI/BOOT/BOOTX64.EFI"
  echo grub_mod_init >"$1/boot/EFI/NixOS-boot/grubx64.efi"
  echo core >"$1/boot/grub/x86_64-efi/core.efi"
}
mklanza() {
  mkdir -p "$1/boot/EFI/BOOT" "$1/boot/EFI/Linux" "$1/boot/EFI/systemd"
  echo '#### LoaderInfo: systemd-boot 257 ####' >"$1/boot/EFI/BOOT/BOOTX64.EFI"
  cp "$1/boot/EFI/BOOT/BOOTX64.EFI" "$1/boot/EFI/systemd/systemd-bootx64.efi"
  echo stub >"$1/boot/EFI/Linux/nixos-generation-3-abc.efi"
}
mkkeys() {
  local d=$1 s
  for s in PK KEK db; do
    mkdir -p "$d/keys/$s"
    echo k >"$d/keys/$s/$s.key"
    echo c >"$d/keys/$s/$s.pem"
  done
  echo guid >"$d/GUID"
}
detect() { MNT=$1; TARGET_GEN=""; detect_bootloader_disk; echo "$DISK_BL"; }

echo -e "\n${BOLD}=== bootloader detection on the disk ===${NC}"
mkgen "$T/grub"; mkgrub "$T/grub"
check "grub tree -> grub" grub "$(detect "$T/grub")"
mkgen "$T/lz" /persist/var/lib/sbctl/keys; mklanza "$T/lz"
check "sbctl.conf + stubs -> lanzaboote" lanzaboote "$(detect "$T/lz")"
mkgen "$T/lzdisk"; mklanza "$T/lzdisk"
check "stubs + systemd-boot, no sbctl.conf -> lanzaboote" lanzaboote "$(detect "$T/lzdisk")"
mkgen "$T/hyb"; mklanza "$T/hyb"
mkdir -p "$T/hyb/boot/grub/x86_64-efi" "$T/hyb/boot/EFI/NixOS-boot"
echo core >"$T/hyb/boot/grub/x86_64-efi/core.efi"
echo grub_mod_init >"$T/hyb/boot/EFI/NixOS-boot/grubx64.efi"
check "hybrid (lanzaboote files + GRUB leftovers) -> lanzaboote" lanzaboote "$(detect "$T/hyb")"
mkgen "$T/hyb2" /persist/var/lib/sbctl/keys; mkgrub "$T/hyb2"
check "sbctl.conf wins over a GRUB BOOTX64 -> lanzaboote" lanzaboote "$(detect "$T/hyb2")"
mkgen "$T/gl"; mkgrub "$T/gl"
mkdir -p "$T/gl/boot/EFI/Linux"; echo stub >"$T/gl/boot/EFI/Linux/nixos-generation-1-x.efi"
check "GRUB BOOTX64 with stale stubs -> grub" grub "$(detect "$T/gl")"
mkgen "$T/oth"; mkdir -p "$T/oth/boot"
check "no evidence -> other" other "$(detect "$T/oth")"
mkdir -p "$T/nogen/boot"
check "no generation at all -> other" other "$(detect "$T/nogen")"
mkdir -p "$T/efi/efi/EFI/Linux" "$T/efi/efi/EFI/BOOT"; mkgen "$T/efi"
echo stub >"$T/efi/efi/EFI/Linux/nixos-generation-2-x.efi"
echo '#### LoaderInfo: systemd-boot 257 ####' >"$T/efi/efi/EFI/BOOT/BOOTX64.EFI"
check "ESP mounted at /efi -> lanzaboote" lanzaboote "$(detect "$T/efi")"
differs "control: grub and lanzaboote trees are told apart" "$(detect "$T/grub")" "$(detect "$T/lz")"

echo -e "\n${BOLD}=== flake answer vs disk ===${NC}"
parse_bl_line "RECOVER-BL:lanzaboote:/persist/var/lib/sbctl"
check "parse: lanzaboote + pkiBundle" "lanzaboote|/persist/var/lib/sbctl" "$FLAKE_BL|$FLAKE_PKI"
parse_bl_line "RECOVER-BL:grub:"
check "parse: grub with empty pkiBundle" "grub|" "$FLAKE_BL|$FLAKE_PKI"
parse_bl_line "garbage"; check "parse: garbage rejected" 1 "$?"
parse_bl_line "RECOVER-BL:weird:/x"; check "parse: unknown bootloader rejected" 1 "$?"
parse_bl_line "RECOVER-BL:grub:"; check "control: a valid line is accepted" 0 "$?"

HOST=fixture-host
resolve() { MNT=$1; TARGET_GEN=""; detect_bootloader_disk; resolve_target_bootloader >/dev/null 2>&1; echo "$TARGET_BL|${TARGET_BL_SRC%% (*}"; }
resolve_with() { ( eval "flake_eval_bootloader() { $1; }"; resolve "$2" ); }
check "flake lanzaboote, disk grub -> flake wins" "lanzaboote|the flake" "$(resolve_with 'echo RECOVER-BL:lanzaboote:/persist/var/lib/sbctl' "$T/grub")"
check "flake grub, disk hybrid -> flake wins" "grub|the flake" "$(resolve_with 'echo RECOVER-BL:grub:/persist/var/lib/sbctl' "$T/hyb")"
check "flake eval fails, disk lanzaboote -> disk" "lanzaboote|the disk" "$(resolve_with 'return 1' "$T/lz")"
check "flake eval fails, disk grub -> disk" "grub|the disk" "$(resolve_with 'return 1' "$T/grub")"
check "flake eval garbage -> disk" "grub|the disk" "$(resolve_with 'echo noise only' "$T/grub")"
check "no flake, no evidence -> other from the disk" "other|the disk" "$(resolve_with 'return 1' "$T/oth")"
differs "control: flake answer vs disk fallback differ on the same tree" "$(resolve_with 'echo RECOVER-BL:lanzaboote:' "$T/grub")" "$(resolve_with 'return 1' "$T/grub")"

echo -e "\n${BOLD}=== flake_eval_bootloader (nixos-enter stubbed) ===${NC}"
mkstub nixos-enter 'if [[ -r $STUB_DATA/enter-out ]]; then cat "$STUB_DATA/enter-out"; fi; [[ ! -e $STUB_DATA/enter-fail ]]'
FLAKE_IN_TARGET=/fixture/flake
WORK=$TW/bl-work; mkdir -p "$WORK"
printf 'warning: noise\nRECOVER-BL:grub:\nRECOVER-BL:lanzaboote:/persist/var/lib/sbctl\ntrailing\n' >"$STUB_DATA/enter-out"
check "last RECOVER-BL line is extracted from noisy output" "RECOVER-BL:lanzaboote:/persist/var/lib/sbctl" "$(flake_eval_bootloader 2>/dev/null)"
touch "$STUB_DATA/enter-fail"
flake_eval_bootloader >/dev/null 2>&1; check "failing nixos-enter -> soft failure (return 1)" 1 "$?"
rm -f "$STUB_DATA/enter-fail" "$STUB_DATA/enter-out"
mkstub nixos-enter 'echo "UNEXPECTED nixos-enter $*" >>"$STUB_LOG"; exit 99'

echo -e "\n${BOLD}=== key paths ===${NC}"
rk() { MNT=$1; TARGET_GEN=""; FLAKE_PKI=${2:-}; resolve_key_paths; echo "$KEYDIR|$GUIDFILE|${KEY_SRC%% (*}"; }
check "flake pkiBundle (impermanence)" "/persist/var/lib/sbctl/keys|/persist/var/lib/sbctl/GUID|the flake" "$(rk "$T/lz" /persist/var/lib/sbctl)"
check "flake pkiBundle (non-impermanence, custom)" "/var/lib/sbctl/keys|/var/lib/sbctl/GUID|the flake" "$(rk "$T/oth" /var/lib/sbctl)"
check "sbctl.conf of the generation (impermanence path)" "/persist/var/lib/sbctl/keys|/persist/var/lib/sbctl/GUID|/etc/sbctl/sbctl.conf of system-3-link" "$(rk "$T/lz")"
mkgen "$T/np" /var/lib/sbctl/keys
check "sbctl.conf of the generation (non-impermanence path)" "/var/lib/sbctl/keys|/var/lib/sbctl/GUID|/etc/sbctl/sbctl.conf of system-3-link" "$(rk "$T/np")"
mkgen "$T/imp"; mkdir -p "$T/imp/persist"
check "default location with /persist on the disk" "/persist/var/lib/sbctl/keys|/persist/var/lib/sbctl/GUID|default location" "$(rk "$T/imp")"
mkgen "$T/noimp"
check "default location without /persist" "/var/lib/sbctl/keys|/var/lib/sbctl/GUID|default location" "$(rk "$T/noimp")"
differs "control: /persist present vs absent moves the default" "$(rk "$T/imp")" "$(rk "$T/noimp")"

echo -e "\n${BOLD}=== signing key presence ===${NC}"
ck() { MNT=$1; KEYDIR=$2; GUIDFILE=${2%/keys}/GUID; check_signing_keys >/dev/null 2>&1; echo "$KEYS_OK"; }
mkdir -p "$T/mut/persist/var/lib/sbctl/keys/db"
echo c >"$T/mut/persist/var/lib/sbctl/keys/db/db.pem"
before=$(ck "$T/mut" /persist/var/lib/sbctl/keys)
echo k >"$T/mut/persist/var/lib/sbctl/keys/db/db.key"
after=$(ck "$T/mut" /persist/var/lib/sbctl/keys)
check "mutation: same tree without db.key -> keys not ok" 0 "$before"
check "mutation: same tree with db.key added -> keys ok" 1 "$after"
rm "$T/mut/persist/var/lib/sbctl/keys/db/db.pem"
check "mutation: db.key without db.pem -> keys not ok" 0 "$(ck "$T/mut" /persist/var/lib/sbctl/keys)"
mkkeys "$T/lz/persist/var/lib/sbctl"
check "impermanence keys present" 1 "$(ck "$T/lz" /persist/var/lib/sbctl/keys)"
mkkeys "$T/np/var/lib/sbctl"
check "non-impermanence keys present" 1 "$(ck "$T/np" /var/lib/sbctl/keys)"
check "keys missing" 0 "$(ck "$T/oth" /persist/var/lib/sbctl/keys)"
mkdir -p "$T/pk"; mkkeys "$T/pk/persist/var/lib/sbctl"
: >"$STUB_LOG"
ck "$T/pk" /var/lib/sbctl/keys >/dev/null
check "keys only in /persist for /var/lib/sbctl -> bind mount attempted" "MOUNT --bind $T/pk/persist/var/lib/sbctl/keys $T/pk/var/lib/sbctl/keys" "$(cat "$STUB_LOG")"
: >"$STUB_LOG"
ck "$T/lz" /persist/var/lib/sbctl/keys >/dev/null
check "control: keys already in place -> no mount" "" "$(cat "$STUB_LOG")"
rm -rf "$T/lz/persist/var/lib/sbctl/keys/PK" "$T/lz/persist/var/lib/sbctl/keys/KEK"
check "PK/KEK missing but db there -> still ok" 1 "$(ck "$T/lz" /persist/var/lib/sbctl/keys)"

echo -e "\n${BOLD}=== sbctl verify classification ===${NC}"
cat >"$T/verify.txt" <<'V'
setting up /etc...
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-5-abc.efi is signed
✓ /boot/EFI/Linux/nixos-generation-5-specialisation-school-def.efi is signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
✗ /boot/EFI/nixos/kernel-6.19-abc.efi is not signed
✗ /boot/EFI/NixOS-boot/grubx64.efi is not signed
✗ /boot/grub/x86_64-efi/core.efi is not signed
✗ /boot/kernels/xyz-bzImage is not signed
✗ /boot/EFI/Microsoft/Boot/bootmgfw.efi is not signed
V
summarize_sbctl_verify "$T/verify.txt"
check "all stubs signed: signed count" 4 "$VERIFY_SIGNED"
check "all stubs signed: nothing bad" 0 "${#VERIFY_BAD[@]}"
check "unsigned kernels, GRUB, Windows are only expected" 5 "${#VERIFY_EXPECTED[@]}"
sed 's#^✓ /boot/EFI/Linux/nixos-generation-5-abc.efi is signed#✗ /boot/EFI/Linux/nixos-generation-5-abc.efi is not signed#' "$T/verify.txt" >"$T/verify-mut.txt"
summarize_sbctl_verify "$T/verify-mut.txt"
check "mutation: one stub unsigned -> exactly one bad" "1|3" "${#VERIFY_BAD[@]}|$VERIFY_SIGNED"
cat >"$T/verify2.txt" <<'V'
\033[1;32m✓\033[0m /boot/EFI/BOOT/BOOTX64.EFI is signed
✗ /boot/EFI/Linux/nixos-generation-6-zzz.efi is not signed
✗ /boot/EFI/systemd/systemd-bootx64.efi is not signed
✗ /boot/efi/boot/bootx64.efi is not signed
V
printf '\033[1;31m\xe2\x9c\x97\033[0m /boot/EFI/Linux/nixos-generation-7-ansi.efi is not signed\n' >>"$T/verify2.txt"
summarize_sbctl_verify "$T/verify2.txt"
check "unsigned stub, systemd-boot, fallback loader, ANSI-coloured stub -> 4 bad" 4 "${#VERIFY_BAD[@]}"
printf 'sbctl: command not found\n' >"$T/verify3.txt"
summarize_sbctl_verify "$T/verify3.txt"
check "no verdict lines -> 0 signed, 0 bad, 0 expected" "0|0|0" "$VERIFY_SIGNED|${#VERIFY_BAD[@]}|${#VERIFY_EXPECTED[@]}"

echo -e "\n${BOLD}=== live Secure Boot state, ESP helpers ===${NC}"
mkdir -p "$EFIVARS_DIR"
SBVAR=$EFIVARS_DIR/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c
check "no SecureBoot variable -> unknown" unknown "$(live_secure_boot)"
printf '\x06\x00\x00\x00\x01' >"$SBVAR"; check "SecureBoot byte 1 -> enforcing" 1 "$(live_secure_boot)"
printf '\x06\x00\x00\x00\x00' >"$SBVAR"; check "SecureBoot byte 0 -> off" 0 "$(live_secure_boot)"
free=$(esp_free_mb "$T")
[[ $free =~ ^[0-9]+$ ]]; check "esp_free_mb prints a number" 0 "$?"
MNT=$T/lz; check "count_stubs counts the fixture stub" 1 "$(count_stubs "$T/lz/boot")"
check "main_esp finds /boot" "$T/lz/boot" "$(main_esp)"
MNT=$T/efi; check "main_esp finds /efi" "$T/efi/efi" "$(main_esp)"
MNT=$T/oth; main_esp >/dev/null; check "main_esp fails without an ESP" 1 "$?"

echo -e "\n${BOLD}=== firmware entry check (efibootmgr, findmnt, blkid, lsblk stubbed) ===${NC}"
MNT=$T/lz
mkdir -p "$SYSFS_BLOCK/fixdisk9p5"; echo 5 >"$SYSFS_BLOCK/fixdisk9p5/partition"
echo /dev/fixdisk9p5 >"$STUB_DATA/findmnt"
echo aaaa-bbbb >"$STUB_DATA/blkid"
echo fixdisk9 >"$STUB_DATA/lsblk"
printf 'Boot0004* UEFI X\tHD(5,GPT,AAAA-BBBB,0x1,0x2)/File(\\EFI\\BOOT\\BOOTX64.EFI)\n' >"$STUB_DATA/efibootmgr-v"
: >"$STUB_LOG"; : >"$WARN_LOG"
fw_entry_check >"$T/fw1.out" 2>&1
check "matching entry -> no warning" 0 "$(grep -c 'No firmware' "$WARN_LOG")"
check "matching entry -> no efibootmgr write" "" "$(cat "$STUB_LOG")"
printf 'Boot0001* Windows\tHD(1,GPT,1111,0x1,0x2)/File(\\EFI\\Microsoft\\Boot\\bootmgfw.efi)\n' >"$STUB_DATA/efibootmgr-v"
: >"$STUB_LOG"; : >"$WARN_LOG"
ASSUME_YES=1 fw_entry_check >"$T/fw2.out" 2>&1
check "no matching entry -> warning" 1 "$(grep -c 'No firmware' "$WARN_LOG")"
check "no matching entry -> exact command printed (disk and partition derived)" "      efibootmgr -c -d /dev/fixdisk9 -p 5 -l '\\EFI\\BOOT\\BOOTX64.EFI' -L 'NixOS lanzaboote'" "$(grep '^      efibootmgr' "$T/fw2.out")"
check "--yes does not create the entry (default no)" "" "$(cat "$STUB_LOG")"
: >"$STUB_LOG"
(ask() { return 0; }; fw_entry_check >/dev/null 2>&1)
check "user says yes -> efibootmgr -c with derived args" "EFIBOOTMGR -c -d /dev/fixdisk9 -p 5 -l \\EFI\\BOOT\\BOOTX64.EFI -L NixOS lanzaboote" "$(cat "$STUB_LOG")"
rm -f "$SYSFS_BLOCK/fixdisk9p5/partition"
: >"$STUB_LOG"; : >"$WARN_LOG"
(ask() { return 0; }; fw_entry_check >/dev/null 2>&1)
check "partition number unreadable -> no write, hand-made command hint" "0|1" "$(grep -c EFIBOOTMGR "$STUB_LOG" || true)|$(grep -c 'Could not work out disk and partition' "$WARN_LOG")"

echo -e "\n${BOLD}=== menu default ===${NC}"
ASSUME_YES=1
check "choose_def --yes picks default 1" 0 "$(choose_def 1 p a b c)"
check "choose_def --yes picks default 3" 2 "$(choose_def 3 p a b c)"
differs "control: the two defaults differ" "$(choose_def 1 p a b c)" "$(choose_def 3 p a b c)"
ASSUME_YES=0
check "choose_def without a tty picks the default" 0 "$(choose_def 1 p a b </dev/null 2>/dev/null)"

echo -e "\n${BOLD}=== lanza_preflight end to end (non-interactive) ===${NC}"
preflight() { # root
  MNT=$1 "$BASH" -c '
    source "$1"; ASSUME_YES=1; FLAKE_PKI=/persist/var/lib/sbctl
    read_gen_file() { local f=$1/var/nix/profiles/$2/$3; [[ -f $f ]] || return 2; printf "%s\n" "$(<"$f")"; }
    info() { echo "I: $*"; }; ok() { :; }; warn() { echo "W: $*"; }
    lanza_preflight; echo rc=$?' _ "$SCRIPT" 2>&1
}
: >"$STUB_LOG"
rm -rf "$T/pfk"; mkgen "$T/pfk"; mkkeys "$T/pfk/persist/var/lib/sbctl"
preflight "$T/pfk" >"$T/pf1.out"
check "keys present -> preflight returns 0" 1 "$(grep -c '^rc=0$' "$T/pf1.out")"
preflight "$T/oth" >"$T/pf2.out"
check "keys missing + --yes -> stops (default is stop)" 1 "$(grep -c 'Stopped. Everything is still mounted' "$T/pf2.out")"
check "keys missing -> never reaches the return" 0 "$(grep -c '^rc=' "$T/pf2.out")"
check "keys missing -> says the signing key is missing" 1 "$(grep -c 'signing key is NOT in /persist/var/lib/sbctl/keys' "$T/pf2.out")"
differs "control: the same call differs with and without keys" "$(grep -c '^rc=0$' "$T/pf1.out")" "$(grep -c '^rc=0$' "$T/pf2.out")"
check "preflight never creates keys, never calls sbctl" "" "$(grep -c 'sbctl' "$STUB_LOG" | sed 's/^0$//')"

echo -e "\n${BOLD}=== hermeticity ===${NC}"
check "no unexpected external tool (sbctl, nix, nixos-enter, chroot, ...) was called" "" "$(grep '^UNEXPECTED' "$STUB_LOG")"
check "nothing was written under the real temp dir by sourcing" 0 "$(find "$TW/own-tmp" -mindepth 1 | wc -l)"

if [[ -z ${RECOVER_IN_MUTANT:-} ]]; then
  echo -e "\n${BOLD}=== mutations of recover.sh must be caught ===${NC}"
  mutant() { # label sed-expression
    local f=$TW/mutant.sh
    sed "$2" "$SCRIPT" >"$f"
    if cmp -s "$f" "$SCRIPT"; then fail "mutant: $1" "sed expression did not change recover.sh"; return; fi
    if RECOVER_IN_MUTANT=1 RECOVER_SCRIPT=$f "$BASH" "${BASH_SOURCE[0]}" >/dev/null 2>&1; then
      fail "mutant: $1" "the checks still pass"
    else
      pass "mutant caught: $1"
    fi
  }
  mutant "db key test looks at KEK" 's#compgen -G "$1/db/\*.key" >/dev/null \&\& compgen#compgen -G "$1/KEK/*.key" >/dev/null \&\& compgen#'
  mutant "sbctl verify never recognises unsigned files" 's#\*"is not signed"\*)#*"is not signedX"*)#'
  mutant "GRUB leftovers no longer detected" 's#DISK_BL=grub DISK_BL_WHY#DISK_BL=other DISK_BL_WHY#'
  mutant "disk beats the flake" 's#TARGET_BL=$FLAKE_BL TARGET_BL_SRC#TARGET_BL=${DISK_BL:-$FLAKE_BL} TARGET_BL_SRC#'
  mutant "firmware entry is created by default" 's#if ask "Create this firmware entry now?" n#if ask "Create this firmware entry now?" y#'
  mutant "missing keys continue by default" 's#choose_def 1 "What now?"#choose_def 3 "What now?"#'
fi

echo
if ((FAIL > 0)); then
  echo -e "${RED}${BOLD}${FAIL} check(s) failed${NC} (${PASS} passed):"
  for f in "${FAILURES[@]}"; do echo "  - $f"; done
  exit 1
fi
echo -e "${GREEN}${BOLD}All ${PASS} checks passed${NC}"
