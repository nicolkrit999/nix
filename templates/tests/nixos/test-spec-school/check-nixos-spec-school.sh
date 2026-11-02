#!/usr/bin/env bash
# School specialisation checks on the real nixos-desktop and nixos-laptop, eval only.
#
# Usage:
#   bash check-nixos-spec-school.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
if [[ -z ${SCHOOL_TEST_TOOLS:-} ]] && ! { command -v jq && command -v rsync && command -v git && command -v findmnt && command -v install; } >/dev/null; then
  SCHOOL_TEST_TOOLS=1 exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#rsync nixpkgs#git nixpkgs#util-linux nixpkgs#gnugrep nixpkgs#coreutils -c bash "$0" "$@"
fi
SCENARIO="$DIR/01-scenario-spec-school.nix"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
DEEP_TEXT=

for h in "${HOSTS[@]}"; do
  (
    export HOST=$h
    nix eval --raw --impure --file "$SCENARIO" report >"$WORK/$h.report" 2>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" scripts >"$WORK/$h.scripts" 2>>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" drvs >"$WORK/$h.drvs" 2>>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" sync >"$WORK/$h.sync" 2>>"$WORK/$h.err"
    echo $? >"$WORK/$h.rc"
  ) &
done
wait

unstore_bin() { sed -E 's#/nix/store/[a-z0-9]{32}-[^/ ]+/bin/([A-Za-z0-9_.+-]+)#\1#g'; }
drv_text() { nix derivation show "$1" | jq -r '.derivations | to_entries[0].value.structuredAttrs.text'; }

write_stubs() {
  cat >"$WORK/stubs.sh" <<'STUBS'
distrobox_stub() {
  local sub=$1 a script="" extra=0 seen=0
  shift
  case $sub in
    create) touch "$STUB_DIR/c.$2" ;;
    enter)
      for a in "$@"; do
        if [ $seen = 1 ]; then script=$a; seen=2
        elif [ $seen = 2 ]; then extra=$((extra + 1))
        elif [ "$a" = -c ]; then seen=1; fi
      done
      printf 'enter %s %s %s %s\n' "$#" "$extra" "$(printf %s "$script" | base64 -w0)" "$(printf %s "${!#}" | base64 -w0)" >>"$STUB_DIR/log"
      case $script in *bsdtar*) [ -r "${!#}" ] && cp -- "${!#}" "$STUB_DIR/rpm-seen" ;; esac
      case $script in "command -v"* | "test -x"*) return 1 ;; esac
      ;;
  esac
  return 0
}
podman_stub() {
  case $1 in
    container) [ -e "$STUB_DIR/c.$3" ] ;;
    exec) printf 'exec %s 0 %s %s\n' "$#" "$(printf %s "${!#}" | base64 -w0)" "$(printf %s "${!#}" | base64 -w0)" >>"$STUB_DIR/log" ;;
  esac
}
STUBS
  cat >"$WORK/deep-stubs.sh" <<'STUBS'
podman_stub() { [ "${STUB_HAVE:-0}" = 1 ]; }
distrobox_stub() { return "${STUB_ENTER_RC:-1}"; }
STUBS
}

rewrite_stubs() {
  sed -E -e "s#/nix/store/[a-z0-9]{32}-school-sqldeveloper-rpm-resolve#$3#g" \
    -e "s#/nix/store/[a-z0-9]{32}-school-stage-file#$4#g" \
    -e 's#/nix/store/[a-z0-9]{32}-coreutils[^/ ]*/bin/##g' \
    -e 's#/nix/store/[a-z0-9]+-(distrobox|podman)[^/ ]*/bin/(distrobox|podman)#\2_stub#g' "$1" >"$2"
}

make_findmnt_stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\nprintf "%%s\\n" %s\n' "$2" >"$1/findmnt"
  chmod +x "$1/findmnt"
}

prepare_resolver() {
  local drv=$1
  {
    echo '#!/usr/bin/env bash'
    echo 'command -v systemd-escape >/dev/null || systemd-escape() { echo unit; }'
    drv_text "$drv" | tail -n +2 | unstore_bin
  } >"$WORK/$h.resolve.sh"
  chmod +x "$WORK/$h.resolve.sh"
}

prepare_stage() {
  local drv=$1
  {
    echo '#!/usr/bin/env bash'
    drv_text "$drv" | tail -n +2 | unstore_bin | sed '/^export PATH=/d'
  } >"$WORK/$h.stage.sh"
  chmod +x "$WORK/$h.stage.sh"
}

run_resolve() {
  local gen=$1 fs=${2:-} bin
  bin=$(mktemp -d "$WORK/rbin.XXXXXX")
  [[ -n $fs ]] && make_findmnt_stub "$bin" "$fs"
  RESOLVE_OUT=$(PATH="$bin:$PATH" HOME="$WORK/$h.rhome" SCHOOL_OPENCLOUD_GENERAL_DIR="$gen" SCHOOL_RPM_MOUNT_TRIES=1 SCHOOL_RPM_MOUNT_SLEEP=0 bash "$WORK/$h.resolve.sh" 2>"$bin/err")
  RESOLVE_RC=$?
  RESOLVE_ERR=$(cat "$bin/err")
}

run_setup_scenario() {
  local tag=$1 gen=$2 fs=$3 d="$WORK/$h.stub.$1"
  mkdir -p "$d/home" "$d/bin"
  cp "$WORK/stubs.sh" "$d/stubs.sh"
  : >"$d/log"
  [[ -n $fs ]] && make_findmnt_stub "$d/bin" "$fs"
  [[ -n ${SETUP_PRE:-} ]] && eval "$SETUP_PRE"
  rewrite_stubs "$WORK/$h.d/school-distrobox-setup" "$d/setup.sh" "$WORK/$h.resolve.sh" "$WORK/$h.stage.sh"
  env "${SETUP_ENV[@]}" STUB_DIR="$d" HOME="$d/home" PATH="$d/bin:$PATH" SCHOOL_OPENCLOUD_GENERAL_DIR="$gen" SCHOOL_RPM_MOUNT_TRIES=1 SCHOOL_RPM_MOUNT_SLEEP=0 \
    bash -c 'source "$1"; source "$2"' _ "$d/stubs.sh" "$d/setup.sh" >"$d/out" 2>&1
  echo $? >"$d/rc"
}
SETUP_ENV=()
SETUP_PRE=""

log_stats() {
  local kind argc extra b64 last text lastp
  N=0 BAD=0 RPMSEEN=0 FOUND=0 ORIGSEEN=0
  while read -r kind argc extra b64 last; do
    N=$((N + 1))
    text=$(printf %s "$b64" | base64 -d)
    lastp=$(printf %s "$last" | base64 -d)
    if [[ $kind == enter ]]; then
      if [[ $extra -eq 0 && $argc -ne 5 ]] || [[ $extra -ne 0 && ($extra -ne 2 || $argc -ne 7 || $lastp != "$2") ]]; then BAD=$((BAD + 1)); fi
      if [[ $extra -eq 2 && $lastp == "$2" && $text == *bsdtar* ]]; then RPMSEEN=$((RPMSEEN + 1)); fi
      if [[ -n ${3:-} && $extra -eq 2 && $lastp == "$3" ]]; then ORIGSEEN=$((ORIGSEEN + 1)); fi
      if [[ $text == *"sed -i"* && $text == *"grep -q 'SetJavaHome'"* && $argc -eq 5 ]]; then FOUND=1; fi
    elif [[ $argc -ne 7 ]]; then
      BAD=$((BAD + 1))
    fi
  done <"$1"
}

log_scripts() {
  local kind argc extra b64 last
  while read -r kind argc extra b64 last; do printf %s "$b64" | base64 -d; echo; done <"$1"
}

file_lacks() { ! grep -qE "$1" "$2"; }
out_has() { grep -qF -- "$1" "$2"; }
out_lacks() { ! grep -qF -- "$1" "$2"; }

stub_run_setup() {
  local rpm_dir gen rpm d dA dB dC dD dE staged stagedir
  d="$WORK/$h.stubcase"
  mkdir -p "$d"
  gen="$d/General Space"
  rpm_dir="$gen/software/oracle-sql-developer"
  rpm="$rpm_dir/sqldeveloper-1.2.3.noarch.rpm"
  mkdir -p "$rpm_dir"
  printf 'rpm-bytes' >"$rpm"
  mkdir -p "$d/plain"

  run_setup_scenario mounted "$gen" ext4
  dA="$WORK/$h.stub.mounted"
  stagedir="$dA/home/.cache/school-distrobox"
  staged="$stagedir/sqldeveloper-1.2.3.noarch.rpm"
  printf "  %-70s " "setup script: no distrobox/podman store path left after stubbing"
  if file_lacks 'bin/(distrobox|podman)' "$dA/setup.sh" && out_has "$WORK/$h.resolve.sh" "$dA/setup.sh" && out_has "$WORK/$h.stage.sh" "$dA/setup.sh"; then pass
  else fail "$h: stub substitution" "a real distrobox/podman path remains or the resolver/stage call was not rewritten"; fi
  printf "  %-70s " "setup script stub-run exits 0 and provisions both containers"
  if [[ $(cat "$dA/rc") -eq 0 && -e $dA/c.school-ubuntu && -e $dA/c.school-arch ]]; then pass; else fail "$h: setup stub-run" "rc=$(cat "$dA/rc"); $(tail -3 "$dA/out" | tr '\n' ' ')"; fi
  log_stats "$dA/log" "$staged" "$rpm"
  printf "  %-70s " "every distrobox enter/podman exec command is exactly one argument"
  if [[ $N -ge 7 && $BAD -eq 0 ]]; then pass; else fail "$h: argument counts" "$BAD of $N invocations have a wrong argument count"; fi
  printf "  %-70s " "sqldeveloper postInstall (sed + grep) is ONE container argument"
  if [[ $FOUND -eq 1 ]]; then pass; else fail "$h: postInstall quoting" "no single-argument invocation holds both the sed and the grep line"; fi
  printf "  %-70s " "STAGED copy (a plain file under ~/.cache/school-distrobox) reaches the container install as one extra argument, once"
  if [[ $RPMSEEN -eq 1 ]]; then pass; else fail "$h: RPM argument" "install invocations carrying the staged path as the last of two extra arguments: $RPMSEEN"; fi
  printf "  %-70s " "the davfs/OpenCloud original path is never passed to a container command"
  if [[ $ORIGSEEN -eq 0 ]]; then pass; else fail "$h: original path in container" "$ORIGSEEN container commands got the OpenCloud path $rpm"; fi
  printf "  %-70s " "the container sees a readable staged file with the original content at install time"
  if [[ -f $dA/rpm-seen && $(cat "$dA/rpm-seen") == rpm-bytes ]]; then pass; else fail "$h: staged content" "staged file unreadable or different at install time: $(cat "$dA/rpm-seen" 2>&1)"; fi
  printf "  %-70s " "after a successful install the staged copy and the empty stage dir are gone, the original is intact"
  if [[ ! -e $staged && ! -e $stagedir && $(cat "$rpm") == rpm-bytes ]]; then pass
  else fail "$h: staged cleanup" "staged=$([[ -e $staged ]] && echo present || echo gone) dir=$([[ -e $stagedir ]] && echo present || echo gone) original=$(cat "$rpm" 2>&1)"; fi

  SETUP_PRE='mkdir -p "$d/home/.cache/school-distrobox" && printf keep >"$d/home/.cache/school-distrobox/keep.txt"'
  run_setup_scenario keepdir "$gen" ext4
  SETUP_PRE=""
  dD="$WORK/$h.stub.keepdir"
  printf "  %-70s " "setup: a stage dir that holds other files keeps them; only the staged copy is removed"
  if [[ $(cat "$dD/rc") -eq 0 && -f $dD/home/.cache/school-distrobox/keep.txt && ! -e $dD/home/.cache/school-distrobox/sqldeveloper-1.2.3.noarch.rpm && $(cat "$dD/rpm-seen") == rpm-bytes ]]; then pass
  else fail "$h: setup keepdir" "rc=$(cat "$dD/rc"); stage dir: $(ls -A "$dD/home/.cache/school-distrobox" 2>&1 | tr '\n' ' ')"; fi

  SETUP_ENV=(SCHOOL_STAGE_MARGIN_BYTES=999999999999999999)
  run_setup_scenario stagefail "$gen" ext4
  SETUP_ENV=()
  dE="$WORK/$h.stub.stagefail"
  printf "  %-70s " "setup, staging fails (not enough space): exit 1, FAILED to stage line, no container install, nothing left staged"
  if [[ $(cat "$dE/rc") -eq 1 ]] && out_has "FAILED to stage the installer for oracle-sqldeveloper" "$dE/out" && out_has "not enough free space" "$dE/out" \
    && out_lacks "Cannot install" "$dE/out" && ! log_scripts "$dE/log" | grep -q bsdtar && [[ ! -e $dE/rpm-seen ]] \
    && [[ -z $(find "$dE/home/.cache" -type f 2>/dev/null) && $(cat "$rpm") == rpm-bytes ]]; then pass
  else fail "$h: setup stage failure" "rc=$(cat "$dE/rc"); $(tail -5 "$dE/out" | tr '\n' ' ')"; fi
  printf "  %-70s " "setup, staging fails: tkgate still installs, the failure is not reported as BLOCKED (exit 3)"
  if out_has "tkgate installed." "$dE/out" && [[ $(cat "$dE/rc") -ne 3 ]]; then pass
  else fail "$h: setup stage failure scope" "tkgate missing or exit 3; $(tail -5 "$dE/out" | tr '\n' ' ')"; fi

  run_setup_scenario missing /proc ""
  dB="$WORK/$h.stub.missing"
  printf "  %-70s " "setup, General space mounted but RPM missing: exit 1, FAILED line, no container install, nothing staged"
  if [[ $(cat "$dB/rc") -eq 1 ]] && out_has "FAILED to install oracle-sqldeveloper" "$dB/out" && out_lacks "Cannot install" "$dB/out" && ! log_scripts "$dB/log" | grep -q bsdtar && [[ ! -e $dB/home/.cache ]]; then pass
  else fail "$h: setup rpm missing" "rc=$(cat "$dB/rc"); $(tail -4 "$dB/out" | tr '\n' ' ')"; fi

  run_setup_scenario unmounted "$d/plain" ""
  dC="$WORK/$h.stub.unmounted"
  printf "  %-70s " "setup, OpenCloud not mounted: exit 3, blocked message, never FAILED or RPM missing"
  if [[ $(cat "$dC/rc") -eq 3 ]] \
    && out_has "Cannot install oracle-sqldeveloper: OpenCloud is not mounted, nothing was installed." "$dC/out" \
    && out_lacks "FAILED to install oracle-sqldeveloper" "$dC/out" && out_lacks "FAILED to stage" "$dC/out" && out_lacks "not found" "$dC/out" && out_lacks "upload it" "$dC/out"; then pass
  else fail "$h: setup not mounted" "rc=$(cat "$dC/rc"); $(tail -5 "$dC/out" | tr '\n' ' ')"; fi
  printf "  %-70s " "setup, OpenCloud not mounted: no container command for SQL Developer, nothing staged, tkgate still installs"
  if ! log_scripts "$dC/log" | grep -qE 'pacman|bsdtar' && out_has "tkgate installed." "$dC/out" && [[ ! -e $dC/home/.cache ]]; then pass
  else fail "$h: setup not mounted containers" "a pacman/bsdtar command ran, something was staged or tkgate did not install"; fi
}

resolver_checks() {
  local d gen rpm line dflt
  d="$WORK/$h.rcase"
  mkdir -p "$d/plain" "$d/General Space/software/oracle-sql-developer" "$d/empty"
  gen="$d/General Space"
  rpm="$gen/software/oracle-sql-developer/sqldeveloper-9.9.9.noarch.rpm"
  : >"$rpm"

  line=$(grep -m1 'dir="${SCHOOL_OPENCLOUD_GENERAL_DIR:-' "$WORK/$h.resolve.sh")
  dflt=${line#*:-}
  dflt=${dflt%\}\"}
  dflt=${dflt//\$HOME/$(jq -r .home "$WORK/$h.drvs")}
  printf "  %-70s " "rpm-resolve: default directory is ~/opencloud/University/0001-General, a school davfs mount"
  if [[ $dflt == "$(jq -r .home "$WORK/$h.drvs")/opencloud/University/0001-General" ]] && jq -e --arg m "$dflt" '.mounts | index($m)' "$WORK/$h.drvs" >/dev/null; then pass
  else fail "$h: rpm-resolve default dir" "default '$dflt' is not the General mount among $(jq -c .mounts "$WORK/$h.drvs")"; fi
  printf "  %-70s " "rpm-resolve: RPM glob is software/oracle-sql-developer/sqldeveloper-*.noarch.rpm in that dir"
  if grep -qF '"$dir"/software/oracle-sql-developer/sqldeveloper-*.noarch.rpm' "$WORK/$h.resolve.sh"; then pass; else fail "$h: rpm-resolve glob" "glob line missing"; fi

  run_resolve "$d/plain"
  printf "  %-70s " "rpm-resolve: plain (not mounted) directory exits 10, no stdout, no RPM-missing text"
  if [[ $RESOLVE_RC -eq 10 && -z $RESOLVE_OUT && $RESOLVE_ERR == *"not mounted"* && $RESOLVE_ERR != *"not found"* && $RESOLVE_ERR != *"upload"* ]]; then pass
  else fail "$h: rpm-resolve 10" "rc=$RESOLVE_RC out='$RESOLVE_OUT' err='$RESOLVE_ERR'"; fi
  run_resolve /proc
  printf "  %-70s " "rpm-resolve: mounted directory without the RPM exits 11 with the upload hint"
  if [[ $RESOLVE_RC -eq 11 && -z $RESOLVE_OUT && $RESOLVE_ERR == *"not found"* && $RESOLVE_ERR == *"upload it"* ]]; then pass
  else fail "$h: rpm-resolve 11" "rc=$RESOLVE_RC out='$RESOLVE_OUT' err='$RESOLVE_ERR'"; fi
  run_resolve "$gen" ext4
  printf "  %-70s " "rpm-resolve: mounted directory with the RPM exits 0 and prints the exact path"
  if [[ $RESOLVE_RC -eq 0 && $RESOLVE_OUT == "$rpm" ]]; then pass; else fail "$h: rpm-resolve 0" "rc=$RESOLVE_RC out='$RESOLVE_OUT'"; fi
  run_resolve "$gen" autofs
  printf "  %-70s " "control: rpm-resolve treats an autofs-only mount as not mounted (exit 10 although the RPM exists)"
  if [[ $RESOLVE_RC -eq 10 && -z $RESOLVE_OUT ]]; then pass; else fail "$h: rpm-resolve autofs" "rc=$RESOLVE_RC out='$RESOLVE_OUT'"; fi
  run_resolve "$d/empty" ext4
  printf "  %-70s " "control: rpm-resolve exits 11, not 10, when a mounted directory merely lacks the RPM"
  if [[ $RESOLVE_RC -eq 11 ]]; then pass; else fail "$h: rpm-resolve mounted empty" "rc=$RESOLVE_RC"; fi
}

run_deep() {
  local tag=$1 have=$2 enter_rc=$3 gen=$4 fs=$5 d="$WORK/$h.deep.$1"
  mkdir -p "$d/bin"
  [[ -n $fs ]] && make_findmnt_stub "$d/bin" "$fs"
  rewrite_stubs "$DEEP_TEXT" "$d/deep.sh" "$WORK/$h.resolve.sh" "$WORK/$h.stage.sh"
  STUB_HAVE=$have STUB_ENTER_RC=$enter_rc PATH="$d/bin:$PATH" HOME="$d" SCHOOL_OPENCLOUD_GENERAL_DIR="$gen" SCHOOL_RPM_MOUNT_TRIES=1 SCHOOL_RPM_MOUNT_SLEEP=0 \
    bash -c 'source "$1"; source "$2"' _ "$WORK/deep-stubs.sh" "$d/deep.sh" >"$d/out" 2>&1
  echo $? >"$d/rc"
}

deep_checks() {
  local d="$WORK/$h.rcase" o
  run_deep nocontainer 0 1 "$d/plain" ""
  o="$WORK/$h.deep.nocontainer"
  printf "  %-70s " "deep check, not mounted: exit 1, cannot verify the RPM, never RPM missing"
  if [[ $(cat "$o/rc") -eq 1 ]] && out_has "oracle-sqldeveloper: cannot verify the RPM: opencloud not mounted" "$o/out" && out_lacks "not found" "$o/out" && out_lacks "upload it" "$o/out"; then pass
  else fail "$h: deep not mounted" "rc=$(cat "$o/rc"); $(tail -5 "$o/out" | tr '\n' ' ')"; fi
  run_deep notinstalled 1 1 "$d/plain" ""
  o="$WORK/$h.deep.notinstalled"
  printf "  %-70s " "deep check, container present but tool missing, not mounted: same verdict"
  if [[ $(cat "$o/rc") -eq 1 ]] && out_has "cannot verify the RPM: opencloud not mounted" "$o/out" && out_lacks "upload it" "$o/out"; then pass
  else fail "$h: deep not installed" "rc=$(cat "$o/rc"); $(tail -5 "$o/out" | tr '\n' ' ')"; fi
  run_deep rpmmissing 0 1 /proc ""
  o="$WORK/$h.deep.rpmmissing"
  printf "  %-70s " "deep check, mounted without RPM: exit 1, upload hint, no cannot-verify message"
  if [[ $(cat "$o/rc") -eq 1 ]] && out_has "upload it" "$o/out" && out_lacks "cannot verify" "$o/out"; then pass
  else fail "$h: deep rpm missing" "rc=$(cat "$o/rc"); $(tail -5 "$o/out" | tr '\n' ' ')"; fi
  run_deep installed 1 0 "$d/plain" ""
  o="$WORK/$h.deep.installed"
  printf "  %-70s " "deep check, everything installed: exit 0 and the resolver is not run"
  if [[ $(cat "$o/rc") -eq 0 ]] && out_has "All distrobox tools are present and verified." "$o/out" && out_lacks "not mounted" "$o/out" && out_lacks "cannot verify" "$o/out"; then pass
  else fail "$h: deep installed" "rc=$(cat "$o/rc"); $(tail -5 "$o/out" | tr '\n' ' ')"; fi
}

tree_sum() { (cd "$1" && find . -mindepth 1 | LC_ALL=C sort | xargs -d '\n' -r cksum 2>/dev/null | cksum); }

sync_checks() {
  local d="$WORK/$h.sync.run" s
  rm -rf "$d"
  mkdir -p "$d/src/.claude/skills" "$d/src/.claude/commands" "$d/dst/.claude/skills" "$d/dst/.claude/agents" "$d/dst/.claude/other" "$d/dst1" "$d/dst3/.claude/skills"
  echo a >"$d/src/.claude/skills/a.md"
  echo c >"$d/src/.claude/commands/c.md"
  echo mcp >"$d/src/.mcp.json"
  echo stale >"$d/dst/.claude/skills/stale.md"
  echo keep >"$d/dst/.claude/agents/keep.md"
  echo keep >"$d/dst/.claude/other/keep.md"
  echo keep >"$d/dst/keepme.txt"
  echo old >"$d/dst/.mcp.json"
  echo keep >"$d/dst1/sentinel"
  echo stale >"$d/dst3/.claude/skills/stale.md"
  sed -E -e 's#^src=.*#src="$TEST_SRC"#' -e 's#^dst=.*#dst="$TEST_DST"#' -e 's# -o [^ ]+ -g [^ ]+##' -e 's# --chown=[^ ]+##' "$WORK/$h.sync" >"$d/sync.sh"
  sed 's# --delete##' "$d/sync.sh" >"$d/sync-nodelete.sh"
  printf "  %-70s " "school-claude-sync: rewritten test copy points at temp dirs, no chown left"
  if grep -qF 'TEST_SRC' "$d/sync.sh" && grep -qF 'TEST_DST' "$d/sync.sh" && file_lacks 'chown| -o ' "$d/sync.sh"; then pass; else fail "$h: sync rewrite" "sed did not rewrite the sync script"; fi
  syntax_check "$h" "school-claude-sync (service script)" "$WORK/$h.sync"

  TEST_SRC="$d/none" TEST_DST="$d/dst1" bash "$d/sync.sh" >"$d/out1" 2>&1
  s=$?
  printf "  %-70s " "school-claude-sync: missing source exits 0 and leaves the destination untouched"
  if [[ $s -eq 0 && $(ls -A "$d/dst1") == sentinel && $(cat "$d/dst1/sentinel") == keep ]] && out_has "nothing to copy" "$d/out1"; then pass
  else fail "$h: sync missing source" "rc=$s; $(cat "$d/out1")"; fi

  local before
  before=$(tree_sum "$d/src")
  TEST_SRC="$d/src" TEST_DST="$d/dst" bash "$d/sync.sh" >"$d/out2" 2>&1
  s=$?
  printf "  %-70s " "school-claude-sync: mirrors skills and commands, copies .mcp.json, source unchanged"
  if [[ $s -eq 0 && $(cat "$d/dst/.claude/skills/a.md") == a && $(cat "$d/dst/.claude/commands/c.md") == c && $(cat "$d/dst/.mcp.json") == mcp && $(tree_sum "$d/src") == "$before" ]]; then pass
  else fail "$h: sync copy" "rc=$s; $(cat "$d/out2")"; fi
  printf "  %-70s " "school-claude-sync: --delete removes stale files only inside a mirrored managed dir"
  if [[ ! -e $d/dst/.claude/skills/stale.md ]]; then pass; else fail "$h: sync delete" "stale file survived inside .claude/skills"; fi
  printf "  %-70s " "school-claude-sync: other dirs, an absent-in-source managed dir and loose files are kept"
  if [[ -e $d/dst/.claude/other/keep.md && -e $d/dst/.claude/agents/keep.md && -e $d/dst/keepme.txt ]]; then pass
  else fail "$h: sync scope" "a file outside the mirrored dirs was deleted"; fi
  TEST_SRC="$d/src" TEST_DST="$d/dst3" bash "$d/sync-nodelete.sh" >"$d/out3" 2>&1
  printf "  %-70s " "control: the same script without --delete keeps the stale file (the delete check can fail)"
  if [[ -e $d/dst3/.claude/skills/stale.md ]]; then pass; else fail "$h: sync control" "stale file vanished without --delete"; fi
}

clone_checks() {
  local d="$WORK/$h.clone.run" s f
  rm -rf "$d"
  mkdir -p "$d/bin" "$d/home1/dotfiles" "$d/home2" "$d/home3"
  echo keep >"$d/home1/dotfiles/marker"
  drv_text "$(jq -r '.clone[0]' "$WORK/$h.drvs")" | unstore_bin >"$d/clone.sh"
  cat >"$d/bin/git" <<'GIT'
#!/bin/sh
echo "$*" >>"$GIT_LOG"
[ -z "${GIT_FAIL:-}" ] || exit 1
for last; do :; done
mkdir -p "$last/.git"
GIT
  chmod +x "$d/bin/git"
  f="$d/clone.sh"
  syntax_check "$h" "school-dotfiles-clone (user unit script)" "$f"
  printf "  %-70s " "school-dotfiles-clone: only git clone of a public https URL, no pull/fetch/reset/checkout/clean"
  if grep -qE 'git clone' "$f" && file_lacks 'git (pull|fetch|reset|checkout|clean|stash|rm)' "$f" && grep -qE 'git clone --quiet https://[^ ]+ ' "$f" && file_lacks 'dotfiles-private|git@' "$f"; then pass
  else fail "$h: clone commands" "script uses another git verb or a private/ssh URL"; fi
  printf "  %-70s " "school-dotfiles-clone: exits early if ~/dotfiles exists; mv is guarded; rm only touches the temp dir"
  if grep -qF '[ -e "$HOME/dotfiles" ] && exit 0' "$f" && grep -qF '[ -e "$HOME/dotfiles" ] || mv' "$f" && ! grep -E '(^|[^a-z])rm ' "$f" | grep -vqF '"$tmp"'; then pass
  else fail "$h: clone guards" "guard or rm scope differs"; fi

  : >"$d/log1"
  PATH="$d/bin:$PATH" HOME="$d/home1" GIT_LOG="$d/log1" bash "$f" >"$d/out1" 2>&1
  s=$?
  printf "  %-70s " "school-dotfiles-clone: an existing ~/dotfiles is neither cloned over nor touched"
  if [[ $s -eq 0 && ! -s $d/log1 && $(cat "$d/home1/dotfiles/marker") == keep && $(ls -A "$d/home1") == dotfiles ]]; then pass
  else fail "$h: clone existing" "rc=$s; git log: $(cat "$d/log1"); home: $(ls -A "$d/home1" | tr '\n' ' ')"; fi

  : >"$d/log2"
  PATH="$d/bin:$PATH" HOME="$d/home2" GIT_LOG="$d/log2" bash "$f" >"$d/out2" 2>&1
  s=$?
  printf "  %-70s " "school-dotfiles-clone: a missing ~/dotfiles is cloned once, no temp dir left behind"
  if [[ $s -eq 0 && -d $d/home2/dotfiles/.git && $(wc -l <"$d/log2") -eq 1 && $(ls -A "$d/home2") == dotfiles ]]; then pass
  else fail "$h: clone missing" "rc=$s; git log: $(cat "$d/log2"); home: $(ls -A "$d/home2" | tr '\n' ' ')"; fi

  : >"$d/log3"
  PATH="$d/bin:$PATH" HOME="$d/home3" GIT_LOG="$d/log3" GIT_FAIL=1 bash "$f" >"$d/out3" 2>&1
  s=$?
  printf "  %-70s " "control: a failing clone leaves no ~/dotfiles and no temp dir and exits non-zero"
  if [[ $s -ne 0 && -z $(ls -A "$d/home3") && -s $d/log3 ]]; then pass
  else fail "$h: clone failure" "rc=$s; home: $(ls -A "$d/home3" | tr '\n' ' ')"; fi
}

run_stage() {
  local src=$1 dir=$2 d="$WORK/$h.stagecase"
  shift 2
  STAGE_OUT=$(env SCHOOL_STAGE_DIR="$dir" "$@" bash "$WORK/$h.stage.sh" "$src" 2>"$d/err")
  STAGE_RC=$?
  STAGE_ERR=$(cat "$d/err")
}

parts_in() { find "$1" -name '*.part*' 2>/dev/null | head -n1; }

stage_checks() {
  local d="$WORK/$h.stagecase" src dest pid i rc9
  rm -rf "$d"
  mkdir -p "$d/General Space" "$d/bin-fail" "$d/bin-short" "$d/bin-slow"
  src="$d/General Space/sqldeveloper-1.2.3.noarch.rpm"
  printf 'rpm-bytes' >"$src"

  printf "  %-70s " "stage: the copy passes the source and the temp name quoted after --"
  if grep -qF -- 'cp -- "$src" "$tmp"' "$WORK/$h.stage.sh"; then pass; else fail "$h: stage copy form" "cp arguments not quoted or not after --"; fi

  dest="$d/s1/sqldeveloper-1.2.3.noarch.rpm"
  run_stage "$src" "$d/s1"
  printf "  %-70s " "stage: copies to <dir>/<basename>, prints exactly that path, leaves no temp file and the source intact"
  if [[ $STAGE_RC -eq 0 && $STAGE_OUT == "$dest" && $(cat "$dest") == rpm-bytes && $(ls -A "$d/s1") == "sqldeveloper-1.2.3.noarch.rpm" && $(cat "$src") == rpm-bytes && $STAGE_ERR == *Staging* ]]; then pass
  else fail "$h: stage copy" "rc=$STAGE_RC out='$STAGE_OUT' dir: $(ls -A "$d/s1" 2>&1 | tr '\n' ' ') err='$STAGE_ERR'"; fi

  mkdir -p "$d/s2"
  printf 'XXXXXXXXX' >"$d/s2/sqldeveloper-1.2.3.noarch.rpm"
  run_stage "$src" "$d/s2"
  printf "  %-70s " "stage: an existing copy of the same size is reused (not rewritten, no copy message)"
  if [[ $STAGE_RC -eq 0 && $STAGE_OUT == "$d/s2/sqldeveloper-1.2.3.noarch.rpm" && $(cat "$d/s2/sqldeveloper-1.2.3.noarch.rpm") == XXXXXXXXX && $STAGE_ERR != *Staging* ]]; then pass
  else fail "$h: stage reuse" "rc=$STAGE_RC content=$(cat "$d/s2/sqldeveloper-1.2.3.noarch.rpm") err='$STAGE_ERR'"; fi

  mkdir -p "$d/s3"
  printf 'short' >"$d/s3/sqldeveloper-1.2.3.noarch.rpm"
  run_stage "$src" "$d/s3"
  printf "  %-70s " "control: an existing copy of another size is replaced by a fresh copy"
  if [[ $STAGE_RC -eq 0 && $(cat "$d/s3/sqldeveloper-1.2.3.noarch.rpm") == rpm-bytes && -z $(parts_in "$d/s3") ]]; then pass
  else fail "$h: stage replace" "rc=$STAGE_RC content=$(cat "$d/s3/sqldeveloper-1.2.3.noarch.rpm")"; fi

  run_stage "$src" "$d/s4" SCHOOL_STAGE_MARGIN_BYTES=999999999999999999
  printf "  %-70s " "stage: not enough free space (size + margin) exits 1 with a clear message, no stdout, no copy, no temp file"
  if [[ $STAGE_RC -eq 1 && -z $STAGE_OUT && $STAGE_ERR == *"not enough free space"* && ! -e $d/s4/sqldeveloper-1.2.3.noarch.rpm && -z $(parts_in "$d/s4") ]]; then pass
  else fail "$h: stage no space" "rc=$STAGE_RC out='$STAGE_OUT' err='$STAGE_ERR'"; fi
  run_stage "$src" "$d/s4b" SCHOOL_STAGE_MARGIN_BYTES=0
  printf "  %-70s " "control: the same file stages fine with a zero margin (only the margin made the previous case fail)"
  if [[ $STAGE_RC -eq 0 && -f $d/s4b/sqldeveloper-1.2.3.noarch.rpm ]]; then pass; else fail "$h: stage margin control" "rc=$STAGE_RC err='$STAGE_ERR'"; fi

  printf '#!/bin/sh\nfor last; do :; done\nprintf part >"$last"\nexit 1\n' >"$d/bin-fail/cp"
  printf '#!/bin/sh\nfor last; do :; done\nprintf rpm >"$last"\nexit 0\n' >"$d/bin-short/cp"
  chmod +x "$d/bin-fail/cp" "$d/bin-short/cp"
  run_stage "$src" "$d/s5" PATH="$d/bin-fail:$PATH"
  printf "  %-70s " "stage: a failing cp exits 1 with a clear message, leaves no destination and the temp file is removed"
  if [[ $STAGE_RC -eq 1 && -z $STAGE_OUT && $STAGE_ERR == *"copy of"*"failed"* && ! -e $d/s5/sqldeveloper-1.2.3.noarch.rpm && -z $(parts_in "$d/s5") ]]; then pass
  else fail "$h: stage cp failure" "rc=$STAGE_RC out='$STAGE_OUT' err='$STAGE_ERR' left: $(ls -A "$d/s5" 2>&1 | tr '\n' ' ')"; fi
  run_stage "$src" "$d/s6" PATH="$d/bin-short:$PATH"
  printf "  %-70s " "stage: a truncated copy (cp exits 0, wrong size) is rejected, never renamed into place, temp file removed"
  if [[ $STAGE_RC -eq 1 && -z $STAGE_OUT && $STAGE_ERR == *"incomplete copy"* && ! -e $d/s6/sqldeveloper-1.2.3.noarch.rpm && -z $(parts_in "$d/s6") ]]; then pass
  else fail "$h: stage short copy" "rc=$STAGE_RC out='$STAGE_OUT' err='$STAGE_ERR' left: $(ls -A "$d/s6" 2>&1 | tr '\n' ' ')"; fi

  run_stage "$d/General Space/none.rpm" "$d/s7"
  printf "  %-70s " "stage: a missing source exits 1 before anything is created"
  if [[ $STAGE_RC -eq 1 && -z $STAGE_OUT && $STAGE_ERR == *"not a readable file"* && ! -e $d/s7 ]]; then pass
  else fail "$h: stage missing source" "rc=$STAGE_RC err='$STAGE_ERR'"; fi
  run_stage "" "$d/s7"
  printf "  %-70s " "stage: an empty source argument exits 1"
  if [[ $STAGE_RC -eq 1 && -z $STAGE_OUT && ! -e $d/s7 ]]; then pass; else fail "$h: stage empty arg" "rc=$STAGE_RC"; fi

  mkdir -p "$d/s8"
  printf 'victim-xx' >"$d/victim"
  ln -s "$d/victim" "$d/s8/sqldeveloper-1.2.3.noarch.rpm"
  run_stage "$src" "$d/s8"
  printf "  %-70s " "stage: a symlink at the destination is replaced, never followed or reused (the link target stays untouched)"
  if [[ $STAGE_RC -eq 0 && ! -L $d/s8/sqldeveloper-1.2.3.noarch.rpm && $(cat "$d/s8/sqldeveloper-1.2.3.noarch.rpm") == rpm-bytes && $(cat "$d/victim") == victim-xx ]]; then pass
  else fail "$h: stage symlink" "rc=$STAGE_RC dest: $(cat "$d/s8/sqldeveloper-1.2.3.noarch.rpm" 2>&1) victim: $(cat "$d/victim")"; fi

  printf '#!/bin/sh\nfor last; do :; done\nprintf part >"$last"\n: >"$STAGE_READY"\nsleep 1\nexit 0\n' >"$d/bin-slow/cp"
  chmod +x "$d/bin-slow/cp"
  rm -f "$d/ready"
  env SCHOOL_STAGE_DIR="$d/s9" STAGE_READY="$d/ready" PATH="$d/bin-slow:$PATH" bash "$WORK/$h.stage.sh" "$src" >"$d/out9" 2>&1 &
  pid=$!
  for i in $(seq 1 50); do [[ -e $d/ready ]] && break; sleep 0.1; done
  kill -TERM "$pid" 2>/dev/null
  wait "$pid"
  rc9=$?
  printf "  %-70s " "stage: SIGTERM during the copy exits 143 and removes the temp file; no destination appears"
  if [[ $rc9 -eq 143 && -e $d/ready && -z $(parts_in "$d/s9") && ! -e $d/s9/sqldeveloper-1.2.3.noarch.rpm ]]; then pass
  else fail "$h: stage SIGTERM" "left: $(ls -A "$d/s9" 2>&1 | tr '\n' ' '); out: $(cat "$d/out9")"; fi
  printf "  %-70s " "stage: the script traps EXIT (temp removal), INT (130) and TERM (143)"
  if grep -qF "trap 'rm -f -- \"\$tmp\"' EXIT" "$WORK/$h.stage.sh" && grep -qF "trap 'exit 130' INT" "$WORK/$h.stage.sh" && grep -qF "trap 'exit 143' TERM" "$WORK/$h.stage.sh"; then pass
  else fail "$h: stage traps" "one of the EXIT/INT/TERM traps is missing"; fi
}

cleanup_checks() {
  local d="$WORK/$h.cleanup" fn out rc
  rm -rf "$d"
  mkdir -p "$d/a" "$d/b" "$d/c" "$d/dd/staged-dir" "$d/e"
  fn=$(awk '/^cleanup_staged\(\) \{/,/^}/' "$WORK/$h.stub.mounted/setup.sh")
  printf "  %-70s " "cleanup_staged: the function is found in the setup script (probe for the cases below)"
  if [[ $fn == *'rm -f -- "$STAGED_FILE"'* ]]; then pass; else fail "$h: cleanup extraction" "cleanup_staged not found in setup.sh"; fi

  printf x >"$d/a/f"
  out=$(CLEAN_FN="$fn" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=$1; cleanup_staged; echo "[$STAGED_FILE]"' _ "$d/a/f")
  printf "  %-70s " "cleanup_staged: removes a plain staged file and then the empty stage dir, and forgets the path"
  if [[ ! -e $d/a && $out == "[]" ]]; then pass; else fail "$h: cleanup plain" "dir: $(ls -A "$d/a" 2>&1) out=$out"; fi

  printf x >"$d/b/f"; printf keep >"$d/b/other"
  CLEAN_FN="$fn" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=$1; cleanup_staged' _ "$d/b/f"
  printf "  %-70s " "cleanup_staged: removes only the staged file; a non-empty stage dir and its other files stay"
  if [[ ! -e $d/b/f && $(cat "$d/b/other") == keep ]]; then pass; else fail "$h: cleanup nonempty" "dir: $(ls -A "$d/b" 2>&1 | tr '\n' ' ')"; fi

  printf victim >"$d/victim"
  ln -s "$d/victim" "$d/c/link"
  CLEAN_FN="$fn" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=$1; cleanup_staged' _ "$d/c/link"
  printf "  %-70s " "cleanup_staged: a symlink at the staged path is neither removed nor followed; its target and dir stay"
  if [[ -L $d/c/link && $(cat "$d/victim") == victim ]]; then pass; else fail "$h: cleanup symlink" "link or target was removed"; fi

  CLEAN_FN="$fn" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=$1; cleanup_staged' _ "$d/dd/staged-dir"
  printf "  %-70s " "cleanup_staged: a directory at the staged path is left alone"
  if [[ -d $d/dd/staged-dir ]]; then pass; else fail "$h: cleanup dir" "directory was removed"; fi

  printf keep >"$d/e/f"
  (cd "$d/e" && CLEAN_FN="$fn" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=""; cleanup_staged; STAGED_FILE=/nonexistent/path; cleanup_staged')
  rc=$?
  printf "  %-70s " "cleanup_staged: an empty or missing staged path is a no-op (nothing else is removed, exit 0)"
  if [[ $rc -eq 0 && $(cat "$d/e/f") == keep && -d $d/e ]]; then pass; else fail "$h: cleanup noop" "no-op cleanup failed or touched the working dir"; fi

  printf "  %-70s " "control: a mutated cleanup (rm -rf instead of rmdir) deletes the sibling file, so the non-empty-dir case can fail"
  mkdir -p "$d/f"; printf keep >"$d/f/other"; printf x >"$d/f/f"
  CLEAN_FN="${fn//rmdir --/rm -rf --}" bash -c 'eval "$CLEAN_FN"; STAGED_FILE=$1; cleanup_staged' _ "$d/f/f"
  if [[ ! -e $d/f/other && $fn != "${fn//rmdir --/rm -rf --}" ]]; then pass; else fail "$h: cleanup control" "the mutated cleanup did not delete the sibling file, so the non-empty-dir case cannot fail"; fi
}

leftovers_checks() {
  local d="$WORK/$h.leftovers" script="$WORK/$h.leftovers.sh" rc
  rm -rf "$d"
  mkdir -p "$d/home1/year/1st/1-semester" "$d/home1/year/1st/2-semester" "$d/home1/year/2nd/3-semester" "$d/home1/year/2nd/4-semester" \
    "$d/home1/year/3rd/6-semester" "$d/home1/projects" "$d/home1/Documents/year/1st/1-semester" "$d/home1/Projects" "$d/victim-dir" "$d/home2/projects"
  printf keep >"$d/home1/year/2nd/3-semester/keep.txt"
  printf keep >"$d/victim-dir/file"
  ln -s "$d/victim-dir" "$d/home1/year/3rd/5-semester"
  printf keep >"$d/home2/projects/work.txt"
  jq -r .leftovers "$WORK/$h.drvs" | sed -E 's#/nix/store/[a-z0-9]{32}-coreutils[^/ ]*/bin/##g' >"$script"
  printf "  %-70s " "bash -n removeEmptySchoolLeftovers (activation script)"
  if bash -n "$script" 2>"$d/syn.err"; then pass; else fail "$h: leftovers syntax" "$(cat "$d/syn.err")"; fi
  printf "  %-70s " "leftovers: the script uses rmdir only (no rm, find, -delete, -r flag, mv)"
  if file_lacks '(^|[^a-z])(rm|find|mv|chmod|chown)( |$)|-delete' "$script" && grep -qE '(^|[ /])rmdir -- ' "$script"; then pass; else fail "$h: leftovers verbs" "a non-rmdir removal verb is present"; fi

  HOME="$d/home1" bash "$script" >"$d/out1" 2>&1
  rc=$?
  printf "  %-70s " "leftovers: old empty ~/year/... and empty ~/projects are removed bottom-up, exit 0"
  if [[ $rc -eq 0 && ! -e $d/home1/year/1st && ! -e $d/home1/year/2nd/4-semester && ! -e $d/home1/year/3rd/6-semester && ! -e $d/home1/projects ]]; then pass
  else fail "$h: leftovers empty" "left: $(cd "$d/home1" && find year projects 2>&1 | tr '\n' ' ')"; fi
  printf "  %-70s " "leftovers: a non-empty old dir keeps its file and every parent (year, year/2nd)"
  if [[ $(cat "$d/home1/year/2nd/3-semester/keep.txt") == keep && -d $d/home1/year/2nd && -d $d/home1/year ]]; then pass
  else fail "$h: leftovers nonempty" "a non-empty directory or a parent was removed"; fi
  printf "  %-70s " "leftovers: a symlink at an old path is never removed or followed (target intact)"
  if [[ -L $d/home1/year/3rd/5-semester && $(cat "$d/victim-dir/file") == keep && -d $d/home1/year/3rd ]]; then pass
  else fail "$h: leftovers symlink" "the symlink or its target was touched"; fi
  printf "  %-70s " "leftovers: the new layout (~/Documents/year/..., ~/Projects) is untouched, even though empty"
  if [[ -d $d/home1/Documents/year/1st/1-semester && -d $d/home1/Projects ]]; then pass; else fail "$h: leftovers new layout" "an empty dir of the new layout was removed"; fi
  HOME="$d/home2" bash "$script" >"$d/out2" 2>&1
  rc=$?
  printf "  %-70s " "leftovers: a non-empty ~/projects and a home without ~/year are left alone, exit 0"
  if [[ $rc -eq 0 && $(cat "$d/home2/projects/work.txt") == keep ]]; then pass; else fail "$h: leftovers projects" "projects content lost or the script failed"; fi
}

log_control() {
  local d="$WORK/log-control" good bad
  mkdir -p "$d"
  good=$(printf %s 'bash -c x' | base64 -w0)
  printf 'enter 5 0 %s %s\nenter 7 2 %s %s\n' "$good" "$good" "$good" "$(printf %s /r | base64 -w0)" >"$d/ok.log"
  printf 'enter 9 0 %s %s\nenter 7 2 %s %s\nexec 6 0 %s %s\n' "$good" "$good" "$good" "$(printf %s /other | base64 -w0)" "$good" "$good" >"$d/bad.log"
  log_stats "$d/ok.log" /r
  good=$BAD
  log_stats "$d/bad.log" /r
  bad=$BAD
  printf "\n  %-70s " "control: the argument-count analysis flags a split command, a wrong RPM argument and a short podman exec"
  if [[ $good -eq 0 && $bad -eq 3 ]]; then pass; else fail "control argument analysis" "clean log flagged $good, broken log flagged $bad of 3"; fi
}

syntax_check() {
  local h=$1 name=$2 file=$3 out
  printf "  %-70s " "bash -n $name"
  if out=$(bash -n "$file" 2>&1); then pass; else fail "$h: bash -n $name" "$out"; fi
}

write_stubs

echo ""
echo -e "${BOLD}=== school specialisation ===${NC}"

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  if [[ $(cat "$WORK/$h.rc") -ne 0 ]]; then
    printf "  %-70s " "evaluate $h"
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r label result; do
    [[ -z $label ]] && continue
    printf "  %-70s " "$label"
    if [[ $result == ok ]]; then pass; else fail "$h: $label" "$result"; fi
  done <"$WORK/$h.report"

  mkdir -p "$WORK/$h.d"
  jq -r 'to_entries[] | "\(.key)\t\(.value | @base64)"' "$WORK/$h.scripts" |
    while IFS=$'\t' read -r name b64; do printf '%s' "$b64" | base64 -d >"$WORK/$h.d/$name"; done
  for f in "$WORK/$h.d"/*; do syntax_check "$h" "$(basename "$f")" "$f"; done

  printf "  %-70s " "rpm-resolve derivation found in the setup script and parses (bash -n)"
  helper_drv=$(jq -r '.helper[0] // empty' "$WORK/$h.drvs")
  if [[ -n $helper_drv ]]; then
    prepare_resolver "$helper_drv"
    if bash -n "$WORK/$h.resolve.sh" 2>"$WORK/$h.resolve.err"; then pass; else fail "$h: rpm-resolve syntax" "$(cat "$WORK/$h.resolve.err")"; fi
  else
    fail "$h: rpm-resolve drv" "no school-sqldeveloper-rpm-resolve derivation in the setup script string context"
    continue
  fi

  for kind in startup deep; do
    for drv in $(jq -r ".$kind[]" "$WORK/$h.drvs"); do
      n=$(basename "$drv" .drv)
      nix derivation show "$drv" | jq -r '.derivations | to_entries[0].value.structuredAttrs.text' >"$WORK/$h.d/$n"
      [[ $kind == deep ]] && DEEP_TEXT="$WORK/$h.d/$n"
      syntax_check "$h" "$n (generated)" "$WORK/$h.d/$n"
      printf "  %-70s " "$n names both containers"
      if grep -q '"school-ubuntu"' "$WORK/$h.d/$n" && grep -q '"school-arch"' "$WORK/$h.d/$n"; then pass
      else fail "$h: $n containers" "school-ubuntu or school-arch missing"; fi
    done
    printf "  %-70s " "$kind check derivation found"
    if [[ $(jq ".$kind | length" "$WORK/$h.drvs") -ge 1 ]]; then pass; else fail "$h: $kind drv" "no derivation in string context"; fi
  done

  printf "  %-70s " "stage-file derivation found in the setup script and parses (bash -n)"
  stage_drv=$(jq -r '.stage[0] // empty' "$WORK/$h.drvs")
  if [[ -n $stage_drv ]]; then
    prepare_stage "$stage_drv"
    if bash -n "$WORK/$h.stage.sh" 2>"$WORK/$h.stage.err"; then pass; else fail "$h: stage syntax" "$(cat "$WORK/$h.stage.err")"; fi
  else
    fail "$h: stage drv" "no school-stage-file derivation in the setup script string context"
    continue
  fi

  stub_run_setup
  stage_checks
  cleanup_checks
  leftovers_checks
  resolver_checks
  printf "  %-70s " "deep check calls the rpm-resolve helper (and no compgen lookup)"
  if out_has "school-sqldeveloper-rpm-resolve" "$DEEP_TEXT" && out_lacks "compgen" "$DEEP_TEXT"; then pass; else fail "$h: deep helper" "deep check does not call the resolver or still globs itself"; fi
  deep_checks
  sync_checks
  clone_checks
done

log_control

printf "\n  %-70s " "control: an unquoted multi-word command splits into several arguments"
set -f
# shellcheck disable=SC2089 # deliberate: the control proves unquoted expansion word-splits under set -f
text="sudo sed -i 's|a|b|' f && echo x"
# shellcheck disable=SC2090 # same deliberate unquoted expansion
set -- enter c -- bash -c $text
set +f
if [[ $# -gt 5 ]]; then pass; else fail "control word splitting" "unquoted text stayed one argument"; fi
printf "  %-70s " "control: bash -n rejects a broken script"
echo 'if then' >"$WORK/broken.sh"
if bash -n "$WORK/broken.sh" 2>/dev/null; then fail "control bash -n" "broken script accepted"; else pass; fi

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}→ $detail${NC}"
done
exit 1
