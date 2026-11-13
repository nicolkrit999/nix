#!/usr/bin/env bash
# Promotion: the machine installed as <host>-2 becomes <host> (the original is retired).
# Run it on the CLONE, in its repository checkout, after the old machine is retired.
#
# Usage: promote.sh --host nixos-desktop|nixos-laptop [--apply] [--repo DIR]
#                   [--nas-root DIR] [--archive-old] [--skip-borg] [--skip-tailnet]
#                   [--delete-old-hardware]
#
# DRY RUN BY DEFAULT: without --apply it only reads (repo files, the NAS mount, `tailscale status`)
# and prints what it would do. --apply prints the same plan, then asks you to type
# `promote <host>` before changing anything.
#
# What it does (each step is independent and safe to re-run):
#   1. repo:  hosts/<host>/system.nix gets the generic hardware layer, flake.nix loses the
#             `"<host>-2" = "<host>";` entry of cloneHosts. Nothing is committed.
#   2. borg:  renames the NAS repository folder borgitory/<host>-2 -> borgitory/<host> through the
#             sshfs mount of the NAS (history kept). An existing borgitory/<host> (the retired
#             machine's) blocks, unless --archive-old renames it to <host>.retired-<date> first.
#   3. tailnet: needs the OLD node deleted from the tailnet first (checked with `tailscale status`).
#             Then runs `tailscale set --hostname=<host>` on this machine and verifies the name.
#   Manual remainder (printed): borg relocation prompt, rebuild, commit, tests, other machines.
#
# Options:
#   --repo DIR       repository checkout (default: the one this script lives in)
#   --nas-root DIR   where the NAS root is mounted (default $PROMOTE_NAS_ROOT or
#                    /mnt/nicol_nas/ssh/system_root, the sshfs mount of krit.services.nas.sshfs)
#   --archive-old    rename an existing borgitory/<host> to <host>.retired-<date> instead of blocking
#   --skip-borg      leave the NAS folder alone (you do it by hand)
#   --skip-tailnet   skip the tailnet check and rename (you do it by hand)
#   --delete-old-hardware  also `git rm` hosts/<host>/hardware-configuration.nix (the old machine's
#                    by-UUID layout) and its flake.nix exclude line, but only when nothing else imports it
#                    and it is clean in git. Default: the file stays (as a reference). Staged, not committed.
#
# Environment: PROMOTE_NAS_ROOT, PROMOTE_DATE (test hook, default today as YYYYMMDD).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

APPLY=0
HOST=""
REPO=$(cd "$SCRIPT_DIR/../.." && pwd)
NAS_ROOT=${PROMOTE_NAS_ROOT:-/mnt/nicol_nas/ssh/system_root}
ARCHIVE_OLD=0
SKIP_BORG=0
SKIP_TAILNET=0
DELETE_OLD_HW=0

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}
step() { printf '\n== %s ==\n' "$*"; }
usage() {
  awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
}

while (($#)); do
  case $1 in
    --host) HOST=${2:?--host needs a value}; shift ;;
    --apply) APPLY=1 ;;
    --repo) REPO=$(cd "${2:?--repo needs a value}" && pwd); shift ;;
    --nas-root) NAS_ROOT=${2:?--nas-root needs a value}; shift ;;
    --archive-old) ARCHIVE_OLD=1 ;;
    --skip-borg) SKIP_BORG=1 ;;
    --skip-tailnet) SKIP_TAILNET=1 ;;
    --delete-old-hardware) DELETE_OLD_HW=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

case $HOST in
  nixos-desktop | nixos-laptop) ;;
  *) die "--host must be nixos-desktop or nixos-laptop" ;;
esac

CLONE=$HOST-2
SYS_FILE=$REPO/hosts/$HOST/system.nix
FLAKE_FILE=$REPO/flake.nix
BORG_FILE=$REPO/users/krit/nixos/services/nas/borg-backup/borg-backup-${HOST#nixos-}.nix
for f in "$SYS_FILE" "$FLAKE_FILE" "$BORG_FILE"; do
  [[ -f $f ]] || die "not found: $f (is --repo a checkout of this repository?)"
done
command -v git >/dev/null 2>&1 || die "git not found in PATH"
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || die "$REPO is not a git checkout"

BLOCKERS=()
NOTES=()
block() { BLOCKERS+=("$*"); }
note() { NOTES+=("$*"); }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/promote.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# act <description> <command...>: run in --apply, print only in a dry run
act() {
  local desc=$1
  shift
  if ((APPLY)); then
    say "  -> $desc"
    "$@"
  else
    say "  [dry-run] $desc"
  fi
}

# ---------------------------------------------------------------------------
# Plan: read-only analysis
# ---------------------------------------------------------------------------
step "Promote $CLONE -> $HOST ($([[ $APPLY == 1 ]] && echo apply || echo dry run))"
say "repository: $REPO"

cur_host=$(hostname 2>/dev/null || true)
case $cur_host in
  "$CLONE") say "this machine: $cur_host (the clone, as expected)" ;;
  "$HOST") warn "this machine is already called $HOST: if this is the promoted clone only the remaining steps matter; if it is the OLD machine, stop"; ;;
  *) block "this machine is '$cur_host', not '$CLONE': run the promotion on the installed clone" ;;
esac

# --- 1. repo -----------------------------------------------------------------
SYS_STATE=unknown
if grep -q 'templates/installer/hardware-select\.nix' "$SYS_FILE"; then
  SYS_STATE=select
elif grep -q 'templates/installer/generic-hardware\.nix' "$SYS_FILE"; then
  SYS_STATE=generic
fi
FLAKE_PAT="^[[:space:]]*\"$CLONE\" = \"$HOST\";[[:space:]]*\$"
if grep -qE -- "$FLAKE_PAT" "$FLAKE_FILE"; then FLAKE_STATE=entry; else FLAKE_STATE=none; fi

REPO_TODO=0
case "$SYS_STATE/$FLAKE_STATE" in
  select/entry)
    REPO_TODO=1
    sed -z -E 's#\(import \.\./\.\./templates/installer/hardware-select\.nix \{[[:space:]]*original = \./hardware-configuration\.nix;[[:space:]]*luks = (true|false);[[:space:]]*\}\)#(import ../../templates/installer/generic-hardware.nix { luks = \1; })#' \
      "$SYS_FILE" >"$TMP/system.nix"
    if cmp -s "$SYS_FILE" "$TMP/system.nix" || ! grep -q 'generic-hardware\.nix' "$TMP/system.nix" \
      || grep -q 'hardware-select\.nix' "$TMP/system.nix"; then
      block "hosts/$HOST/system.nix has a hardware-select import in a shape this script does not recognise: edit it by hand (see Documentation/installation/clone-retire-and-promote.md)"
    fi
    grep -vE -- "$FLAKE_PAT" "$FLAKE_FILE" >"$TMP/flake.nix" || true
    if (($(wc -l <"$FLAKE_FILE") - $(wc -l <"$TMP/flake.nix") != 1)); then
      block "flake.nix: expected to remove exactly one cloneHosts line for $CLONE"
    fi
    dirty=$(git -C "$REPO" status --porcelain -- flake.nix "hosts/$HOST/system.nix")
    [[ -z $dirty ]] || block "uncommitted changes in flake.nix or hosts/$HOST/system.nix: commit or stash them first"
    ;;
  generic/none) say "repo: already promoted (generic hardware layer, no $CLONE entry): nothing to edit" ;;
  *) block "repo is half-promoted or unrecognised (system.nix: $SYS_STATE, cloneHosts entry: $FLAKE_STATE): fix by hand" ;;
esac

# --- 1b. old hardware file (optional) ----------------------------------------
HW_REL=hosts/$HOST/hardware-configuration.nix
HW_FILE=$REPO/$HW_REL
HW_EXCLUDE_PAT="^[[:space:]]*\./hosts/$HOST/hardware-configuration\.nix[[:space:]]*\$"
HW_TODO=0
if ((DELETE_OLD_HW)); then
  if [[ ! -e $HW_FILE ]]; then
    say "old hardware: $HW_REL is already gone"
  elif ! git -C "$REPO" ls-files --error-unmatch -- "$HW_REL" >/dev/null 2>&1; then
    block "$HW_REL is not tracked by git: remove it by hand"
  elif [[ -n $(git -C "$REPO" status --porcelain -- "$HW_REL") ]]; then
    block "uncommitted changes in $HW_REL: commit or stash them first (--delete-old-hardware)"
  elif ((REPO_TODO == 0)) && [[ -n $(git -C "$REPO" status --porcelain -- flake.nix) ]]; then
    block "uncommitted changes in flake.nix: commit or stash them first (--delete-old-hardware)"
  else
    # a reference is any non-comment .nix line naming the file that belongs to this host (a file in
    # hosts/<host>/, or a path with <host>/hardware-configuration), apart from the flake.nix exclude
    # line (removed together with the file) and system.nix, which is read in its post-promotion form
    sys_after=$SYS_FILE
    [[ $SYS_STATE == select && -f $TMP/system.nix ]] && sys_after=$TMP/system.nix
    importers=""
    while IFS= read -r hit; do
      f=${hit%%:*}
      rest=${hit#*:}
      rest=${rest#*:}
      [[ $f == "$FLAKE_FILE" ]] && grep -qE -- "$HW_EXCLUDE_PAT" <<<"$rest" && continue
      [[ $f == "$SYS_FILE" ]] && continue
      [[ $rest =~ ^[[:space:]]*# ]] && continue
      case $f in
        "$REPO/hosts/$HOST/"*) ;;
        *) grep -qF -- "$HOST/hardware-configuration" <<<"$rest" || continue ;;
      esac
      importers+="${f#"$REPO"/}: ${rest## }"$'\n'
    done < <(grep -rIn --include='*.nix' --exclude-dir=.git -F -e hardware-configuration "$REPO" || true)
    if grep -v '^[[:space:]]*#' "$sys_after" | grep -q 'hardware-configuration'; then
      importers+="hosts/$HOST/system.nix still names hardware-configuration"$'\n'
    fi
    if [[ -n $importers ]]; then
      block "$HW_REL is still referenced, not deleting it: ${importers//$'\n'/; }"
    else
      HW_TODO=1
    fi
  fi
fi

# --- 2. borg -----------------------------------------------------------------
# shellcheck disable=SC2016 # the ${...} is literal Nix text, not a shell expansion
BORG_BASE=$(sed -n 's#^[[:space:]]*nasPath = "\(/[^"]*\)/\${config\.networking\.hostName}";#\1#p' "$BORG_FILE" | head -n 1)
BORG_CFG=$(sed -n 's#^[[:space:]]*configurations\."\([^"]*\)".*#\1#p' "$BORG_FILE" | head -n 1)
BORG_TODO=none
BORG_SRC="" BORG_DST="" BORG_ARCHIVE=""
if ((SKIP_BORG)); then
  say "borg: skipped (--skip-borg)"
elif [[ -z $BORG_BASE || -z $BORG_CFG ]]; then
  block "could not read the borg repository path from ${BORG_FILE#"$REPO"/}"
else
  borg_dir=$NAS_ROOT$BORG_BASE
  BORG_SRC=$borg_dir/$CLONE
  BORG_DST=$borg_dir/$HOST
  BORG_ARCHIVE=$borg_dir/$HOST.retired-${PROMOTE_DATE:-$(date +%Y%m%d)}
  say "borg: repository folders under $borg_dir"
  if ! timeout 30 test -d "$borg_dir" 2>/dev/null; then
    BORG_TODO=unreachable
    block "NAS folder $borg_dir is not reachable (sshfs mount down, tailnet off?): open the mount and retry, or use --skip-borg and rename on the NAS by hand"
  elif [[ -d $BORG_SRC ]]; then
    if [[ ! -f $BORG_SRC/config || ! -d $BORG_SRC/data ]]; then
      block "$BORG_SRC exists but does not look like a borg repository (no config or data)"
    elif [[ -e $BORG_SRC/lock.exclusive || -e $BORG_SRC/lock.roster ]]; then
      block "$BORG_SRC is locked (a backup is running or died): wait for it, or run 'borg break-lock' deliberately"
    elif systemctl is-active --quiet borgmatic.service 2>/dev/null; then
      block "borgmatic.service is running right now: wait for the backup to finish"
    elif [[ -e $BORG_DST ]]; then
      if ((ARCHIVE_OLD)); then
        if [[ -e $BORG_ARCHIVE ]]; then
          block "$BORG_ARCHIVE already exists: move it away first"
        else
          BORG_TODO=archive-and-rename
        fi
      else
        block "$BORG_DST already exists (the retired machine's repository): use --archive-old to keep it as $(basename "$BORG_ARCHIVE"), or move it away by hand"
      fi
    else
      BORG_TODO=rename
    fi
  elif [[ -d $BORG_DST ]]; then
    say "borg: $CLONE folder is gone and $HOST exists: already renamed"
  else
    note "borg: neither $CLONE nor $HOST exists under $borg_dir (the clone never backed up?): nothing to rename"
  fi
fi

# --- 3. tailnet --------------------------------------------------------------
TS_STATE=skipped
if ((SKIP_TAILNET)); then
  say "tailnet: skipped (--skip-tailnet)"
elif ! command -v tailscale >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  TS_STATE=unknown
  block "tailscale or jq not found: cannot check the tailnet. Do the name steps by hand and use --skip-tailnet"
elif ! ts_json=$(tailscale status --json 2>/dev/null) || ! jq -e '.Self' <<<"$ts_json" >/dev/null 2>&1; then
  TS_STATE=unknown
  block "'tailscale status' did not answer: this machine is not on the tailnet. Bring it up, or use --skip-tailnet"
else
  self_label=$(jq -r '.Self.DNSName // "" | split(".")[0]' <<<"$ts_json")
  others=$(jq -r --arg h "$HOST" '[.Peer[]? | select(.HostName == $h or ((.DNSName // "") | split(".")[0]) == $h)] | length' <<<"$ts_json")
  if [[ $self_label == "$HOST" ]]; then
    TS_STATE=renamed
    say "tailnet: this node is already called $HOST"
  elif ((others > 0)); then
    TS_STATE=old-present
    block "the tailnet still has another node named '$HOST' (the old machine): delete it in the admin console (Machines > $HOST > Delete) so the name is free, then retry"
  else
    TS_STATE=free
    say "tailnet: node is '$self_label', the name '$HOST' is free"
  fi
fi

# --- remaining references ----------------------------------------------------
say ""
say "other mentions of $CLONE in the repository (review by hand, the installer contract is excluded):"
refs=$(grep -rIn --exclude-dir=.git --exclude-dir=installer --exclude-dir=test-clone-installer \
  --exclude-dir=installation -F -e "$CLONE" "$REPO" | grep -v "^$REPO/flake.nix:" || true)
if [[ -n $refs ]]; then
  while IFS= read -r l; do say "  ${l#"$REPO"/}" | cut -c1-160; done <<<"$refs"
else
  say "  none"
fi

# --- plan --------------------------------------------------------------------
step "Plan"
((REPO_TODO)) && {
  say "1. repo: hosts/$HOST/system.nix -> generic hardware layer; flake.nix: remove \"$CLONE\" from cloneHosts"
  ((DELETE_OLD_HW)) || say "   (hosts/$HOST/hardware-configuration.nix stays; delete it later if you do not need it as a reference)"
}
((HW_TODO)) && say "1b. old hardware: git rm $HW_REL and remove its exclude line from flake.nix (nothing else imports it)"
case $BORG_TODO in
  rename) say "2. borg: mv $BORG_SRC -> $BORG_DST" ;;
  archive-and-rename) say "2. borg: mv $BORG_DST -> $BORG_ARCHIVE, then mv $BORG_SRC -> $BORG_DST" ;;
  *) say "2. borg: nothing to rename" ;;
esac
case $TS_STATE in
  free) say "3. tailnet: tailscale set --hostname=$HOST, then verify the node name" ;;
  *) say "3. tailnet: nothing to do automatically ($TS_STATE)" ;;
esac
for n in "${NOTES[@]}"; do say "note: $n"; done
if ((${#BLOCKERS[@]})); then
  say ""
  say "NOT READY, blockers:"
  for b in "${BLOCKERS[@]}"; do say "  - $b"; done
fi

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------
delete_old_hardware() {
  git -C "$REPO" rm -q -- "$HW_REL"
  grep -vE -- "$HW_EXCLUDE_PAT" "$FLAKE_FILE" >"$TMP/flake-hw.nix" || true
  cat "$TMP/flake-hw.nix" >"$FLAKE_FILE"
}

write_repo() {
  cat "$TMP/system.nix" >"$SYS_FILE"
  cat "$TMP/flake.nix" >"$FLAKE_FILE"
}

if ((APPLY)); then
  ((${#BLOCKERS[@]} == 0)) || die "blockers above: nothing was changed"
  if ((REPO_TODO == 0 && HW_TODO == 0)) && [[ $BORG_TODO == none && $TS_STATE != free ]]; then
    say ""
    say "Nothing to apply."
  else
    say ""
    printf 'Type exactly "promote %s" to apply the plan above (anything else aborts): ' "$HOST"
    IFS= read -r reply || die "no input (stdin closed), nothing was changed"
    [[ $reply == "promote $HOST" ]] || die "confirmation mismatch, nothing was changed"

    step "Applying"
    case $BORG_TODO in
      rename) act "mv $BORG_SRC -> $BORG_DST" mv -T -- "$BORG_SRC" "$BORG_DST" ;;
      archive-and-rename)
        act "mv $BORG_DST -> $BORG_ARCHIVE" mv -T -- "$BORG_DST" "$BORG_ARCHIVE"
        act "mv $BORG_SRC -> $BORG_DST" mv -T -- "$BORG_SRC" "$BORG_DST"
        ;;
    esac
    if [[ $TS_STATE == free ]]; then
      act "tailscale set --hostname=$HOST" tailscale set --hostname="$HOST"
      if ts_json=$(tailscale status --json 2>/dev/null); then
        new_label=$(jq -r '.Self.DNSName // "" | split(".")[0]' <<<"$ts_json")
        if [[ $new_label == "$HOST" ]]; then
          say "  tailnet node is now called $HOST"
        else
          warn "tailnet node is called '$new_label', not '$HOST' (a leftover node with that name?): rename it in the admin console"
        fi
      else
        warn "could not re-read 'tailscale status'; check the node name by hand"
      fi
    fi
    ((REPO_TODO)) && act "write hosts/$HOST/system.nix and flake.nix" write_repo
    ((HW_TODO)) && act "git rm $HW_REL and its flake.nix exclude line" delete_old_hardware
  fi
fi

# ---------------------------------------------------------------------------
# What stays manual
# ---------------------------------------------------------------------------
step "Next steps (manual)"
if ((APPLY)); then
  say "Done above. Still to do, in this order:"
else
  say "This was a dry run, nothing was changed. After --apply, in this order:"
fi
cat <<EOF
  1. Rebuild promptly (the borg timer runs once a day; a run between the rename and the switch only
     fails, it harms nothing):
       cd $REPO
       nix eval --raw .#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath
       nh os switch . --hostname $HOST
  2. Borg: the repository location changed, so borg asks once to confirm the relocation and a
     non-interactive run aborts until you do (its security dir and cache remember the old path):
       sudo env BORG_RELOCATED_REPO_ACCESS_IS_OK=yes borgmatic -c /etc/borgmatic.d/${BORG_CFG:-<name>}.yaml info
     then check the next scheduled run in 'journalctl -u borgmatic'.
  3. Tailnet: 'tailscale status' must show $HOST. If the node is still '$CLONE' or got a '-1' suffix:
     delete the stale node in the admin console (the old machine's) and 'sudo tailscale set --hostname=$HOST'.
     Fix anything on other machines that refers to $CLONE (ssh config, shortcuts).
  4. Sops: nothing to do (constants.hostname already is $HOST); confirm secrets still decrypt.
  5. Run 'nix flake check' and the affected tests (flake outputs, the clone installer test, common
     host tests), review the leftovers listed above, then COMMIT AND PUSH yourself.
EOF
