#!/usr/bin/env bash
# Usage:
#   bash check-nixos-yazi-open-with.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-yazi-open-with.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0
FAIL=0
declare -a FAILURES=()

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

record() {
  local label="$1" ok="$2" detail="${3:-}"
  printf "  %-66s " "$label"
  if [[ "$ok" == 1 ]]; then
    printf "${GREEN}PASS${NC}\n"; ((PASS++)) || true
  else
    printf "${RED}FAIL${NC}\n"; ((FAIL++)) || true
    FAILURES+=("$label|$detail")
  fi
}

finish() {
  echo ""
  if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
    exit 0
  fi
  echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
  local entry label detail
  for entry in "${FAILURES[@]}"; do
    IFS="|" read -r label detail <<< "$entry"
    echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
    [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
  done
  exit 1
}

echo ""
echo -e "${BOLD}=== yazi 'Open with' entry (eval layer) ===${NC}"
echo ""

stderr_file="$WORK/eval.err"
if ! json=$(FLAKE_ROOT="$REPO_ROOT" nix eval --json --impure --file "$SCENARIO" 2>"$stderr_file"); then
  record "scenario evaluation" 0 "$(grep -E 'error:' "$stderr_file" | head -3 | tr '\n' '~')"
  finish
fi

while IFS=$'\t' read -r name result; do
  if [[ "$result" == "ok" ]]; then record "$name" 1; else record "$name" 0 "$result"; fi
done < <(jq -r '.checks | to_entries[] | [.key, .value] | @tsv' <<<"$json")

echo ""
echo -e "${BOLD}=== yazi-open-with helper (shipped script, stubbed gio / fzf / gtk-launch) ===${NC}"
echo ""

HELPER_DRV="$(jq -r '.helperDrv' <<<"$json")"
if ! HELPER_OUT=$(nix build --no-link --print-out-paths "${HELPER_DRV}^out" 2>"$stderr_file" | head -1) || [[ -z "$HELPER_OUT" ]]; then
  record "build the shipped yazi-open-with helper" 0 "$(grep -E 'error:' "$stderr_file" | head -3 | tr '\n' '~')"
  finish
fi
SHIPPED="$HELPER_OUT/bin/yazi-open-with"
REAL="$WORK/helper.sh"
sed '/^export PATH=/d' "$SHIPPED" >"$REAL"

BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/fix/dir with space"
FIXDIR="$(cd "$WORK/fix" && pwd -P)"
FILE_PLAIN="$FIXDIR/note.txt"
FILE_SPACES="$FIXDIR/dir with space/my file (1) 'q' \$x.txt"
FILE_DASH="-dash file.txt"
touch "$FILE_PLAIN" "$FILE_SPACES" "$FIXDIR/$FILE_DASH"

cat >"$BIN/gio" <<'STUB'
#!/usr/bin/env bash
{ printf 'CALL'; printf ' <%s>' "$@"; printf '\n'; } >>"$STUB_DIR/gio.log"
case "$1" in
  info)
    printf 'uri: file:///stub\nattributes:\n'
    if [ -n "${STUB_MIME:-}" ] && [ -e "${*: -1}" ]; then
      printf '  standard::content-type: %s\n' "$STUB_MIME"
    fi
    ;;
  mime)
    printf '%s\n' "${LC_ALL-unset}" >"$STUB_DIR/gio-mime-lcall"
    cat "$STUB_LISTING"
    ;;
esac
STUB
cat >"$BIN/fzf" <<'STUB'
#!/usr/bin/env bash
cat >"$STUB_DIR/fzf.in"
printf '%s\n' "$@" >"$STUB_DIR/fzf.args"
case "${STUB_FZF:-}" in
  esc) exit 130 ;;
  nomatch) exit 1 ;;
  empty) exit 0 ;;
  pick:*) sed -n "${STUB_FZF#pick:}p" "$STUB_DIR/fzf.in"; exit 0 ;;
esac
exit 99
STUB
cat >"$BIN/gtk-launch" <<'STUB'
#!/usr/bin/env bash
{ printf 'LAUNCH'; printf ' <%s>' "$@"; printf '\n'; } >>"$STUB_DIR/launch.log"
STUB
chmod +x "$BIN"/gio "$BIN"/fzf "$BIN"/gtk-launch

LISTING_MAIN=$'Default application for \'text/plain\': custom-nvim.desktop\nRegistered applications:\n\temacs.desktop\n\tcustom-nvim.desktop\n\torg.kde.kate.desktop\n\torg.gnome.TextEditor.desktop\nRecommended applications:\n\temacs.desktop\n\torg.kde.kate.desktop\n\tcom.github.tchx84.Flatseal.desktop\n'
EXPECTED_MAIN=$'* custom-nvim.desktop\n  emacs.desktop\n  org.kde.kate.desktop\n  org.gnome.TextEditor.desktop\n  com.github.tchx84.Flatseal.desktop'
LISTING_ONLY_DEFAULT=$'Default application for \'a/b\': only.desktop\n'
LISTING_NO_DEFAULT=$'No default applications for \'a/b\'\nRegistered applications:\n\ta.desktop\n\tb.desktop\n'
LISTING_NONE=$'No default applications for \'a/b\'\nNo registered applications\n'

RUN_N=0
RC=0
R=""
DETAIL=""

run_helper() {
  local script="$1" mime="$2" listing="$3" fzf="$4"
  shift 4
  RUN_N=$((RUN_N + 1))
  R="$WORK/run.$RUN_N"
  mkdir -p "$R"
  printf '%s' "$listing" >"$R/listing"
  RC=0
  (
    cd "$FIXDIR" || exit 97
    unset LC_ALL
    PATH="$BIN:$PATH" STUB_DIR="$R" STUB_MIME="$mime" STUB_LISTING="$R/listing" STUB_FZF="$fzf" \
      bash "$script" "$@" >"$R/out" 2>"$R/err"
  ) || RC=$?
  DETAIL="rc=$RC err=$(flat "$R/err") fzf-in=$(flat "$R/fzf.in") launch=$(flat "$R/launch.log")"
}

flat() { [[ -e "$1" ]] && tr '\n' '|' <"$1"; }

launch_is() { [[ "$(cat "$R/launch.log" 2>/dev/null)" == "$1" ]]; }
no_launch() { [[ ! -s "$R/launch.log" ]]; }
fzf_input_is() { [[ -e "$R/fzf.in" && "$(cat "$R/fzf.in")" == "$1" ]]; }

c_order_marker_dedupe() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is "$EXPECTED_MAIN"
}
c_prompt_has_title_and_mime() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FILE_PLAIN"
  grep -Fxq -- '--prompt=Menu (text/plain)> ' "$R/fzf.args" 2>/dev/null
}
c_launch_default() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && launch_is "LAUNCH <custom-nvim.desktop> <$FILE_PLAIN>"
}
c_launch_other_strips_marker() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:3 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && launch_is "LAUNCH <org.kde.kate.desktop> <$FILE_PLAIN>"
}
c_flatpak_ids_pass_through() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:5 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && launch_is "LAUNCH <com.github.tchx84.Flatseal.desktop> <$FILE_PLAIN>" || return 1
  run_helper "$1" text/plain "$LISTING_MAIN" pick:4 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && launch_is "LAUNCH <org.gnome.TextEditor.desktop> <$FILE_PLAIN>"
}
c_esc_exits_zero_no_launch() {
  run_helper "$1" text/plain "$LISTING_MAIN" esc "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is "$EXPECTED_MAIN" && no_launch
}
c_empty_selection_exits_zero_no_launch() {
  run_helper "$1" text/plain "$LISTING_MAIN" empty "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is "$EXPECTED_MAIN" && no_launch
}
c_no_match_exits_zero_no_launch() {
  run_helper "$1" text/plain "$LISTING_MAIN" nomatch "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is "$EXPECTED_MAIN" && no_launch
}
c_unknown_mime_message_nonzero() {
  run_helper "$1" "" "$LISTING_MAIN" pick:1 "$FILE_PLAIN"
  [[ $RC -ne 0 ]] && grep -q 'could not determine the MIME type' "$R/err" && [[ ! -e "$R/fzf.in" ]] && no_launch
}
c_no_apps_message_nonzero() {
  run_helper "$1" a/b "$LISTING_NONE" pick:1 "$FILE_PLAIN"
  [[ $RC -ne 0 ]] && grep -q 'no applications are associated with a/b' "$R/err" && [[ ! -e "$R/fzf.in" ]] && no_launch
}
c_only_default_listed() {
  run_helper "$1" a/b "$LISTING_ONLY_DEFAULT" pick:1 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is "* only.desktop" && launch_is "LAUNCH <only.desktop> <$FILE_PLAIN>"
}
c_no_default_no_marker() {
  run_helper "$1" a/b "$LISTING_NO_DEFAULT" pick:2 "$FILE_PLAIN"
  [[ $RC -eq 0 ]] && fzf_input_is $'  a.desktop\n  b.desktop' && launch_is "LAUNCH <b.desktop> <$FILE_PLAIN>"
}
c_spaces_in_file_name() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:2 "$FILE_SPACES"
  [[ $RC -eq 0 ]] \
    && launch_is "LAUNCH <emacs.desktop> <$FILE_SPACES>" \
    && grep -Fxq -- "CALL <info> <--attributes=standard::content-type> <--> <$FILE_SPACES>" "$R/gio.log"
}
c_dash_relative_file_name() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FILE_DASH"
  [[ $RC -eq 0 ]] && launch_is "LAUNCH <custom-nvim.desktop> <$FIXDIR/$FILE_DASH>"
}
c_gio_mime_runs_in_c_locale() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FILE_PLAIN"
  [[ "$(cat "$R/gio-mime-lcall" 2>/dev/null)" == "C" ]]
}
c_missing_file_nonzero() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FIXDIR/does-not-exist"
  [[ $RC -eq 1 ]] && grep -q 'could not determine the MIME type' "$R/err" && [[ ! -e "$R/fzf.in" ]] && no_launch || return 1
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 "$FIXDIR/no-such-dir/file"
  [[ $RC -eq 1 ]] && grep -q 'no such file' "$R/err" && [[ ! -e "$R/fzf.in" ]] && no_launch
}
c_missing_argument_usage() {
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1
  [[ $RC -eq 2 ]] && grep -q 'usage:' "$R/err" || return 1
  run_helper "$1" text/plain "$LISTING_MAIN" pick:1 ""
  [[ $RC -eq 2 ]] && no_launch
}

CASES=(
  "order-default-first-marker-deduped|c_order_marker_dedupe"
  "prompt-shows-Menu-and-mime|c_prompt_has_title_and_mime"
  "choosing-default-launches-it|c_launch_default"
  "choosing-other-strips-marker|c_launch_other_strips_marker"
  "flatpak-ids-pass-through-unchanged|c_flatpak_ids_pass_through"
  "esc-exits-0-and-launches-nothing|c_esc_exits_zero_no_launch"
  "empty-selection-exits-0-and-launches-nothing|c_empty_selection_exits_zero_no_launch"
  "no-match-exits-0-and-launches-nothing|c_no_match_exits_zero_no_launch"
  "unknown-mime-message-and-nonzero|c_unknown_mime_message_nonzero"
  "no-apps-message-and-nonzero|c_no_apps_message_nonzero"
  "only-default-app-is-listed|c_only_default_listed"
  "no-default-means-no-marker|c_no_default_no_marker"
  "file-name-with-spaces-stays-one-argument|c_spaces_in_file_name"
  "dash-leading-relative-name-made-absolute|c_dash_relative_file_name"
  "gio-mime-runs-with-LC_ALL-C|c_gio_mime_runs_in_c_locale"
  "missing-file-message-and-exit-1|c_missing_file_nonzero"
  "missing-argument-prints-usage-exit-2|c_missing_argument_usage"
)

for entry in "${CASES[@]}"; do
  IFS='|' read -r label fn <<<"$entry"
  if "$fn" "$REAL"; then record "helper: $label" 1; else record "helper: $label" 0 "$DETAIL"; fi
done

echo ""
echo -e "${BOLD}runtime inputs${NC}"

PATH_LINE="$(sed -n 's/^export PATH="\(.*\):\$PATH"$/\1/p' "$SHIPPED")"
tool_in_path() { ( PATH="$1"; command -v "$2" >/dev/null 2>&1 ); }
missing_tools() {
  local t out=""
  for t in gio fzf gtk-launch awk sed realpath head; do
    tool_in_path "$1" "$t" || out+="$t "
  done
  printf '%s' "$out"
}

if [[ "$(grep -c '^export PATH=' "$SHIPPED")" == 1 && "$(grep -c '^export PATH=' "$REAL")" == 0 && -n "$PATH_LINE" ]]; then
  record "helper: the shipped script prepends its own runtime PATH" 1
else
  record "helper: the shipped script prepends its own runtime PATH" 0 "expected exactly one export PATH= line in $SHIPPED"
fi
missing="$(missing_tools "$PATH_LINE")"
if [[ -z "$missing" ]]; then
  record "helper: the runtime PATH alone provides gio fzf gtk-launch awk sed realpath head" 1
else
  record "helper: the runtime PATH alone provides gio fzf gtk-launch awk sed realpath head" 0 "missing: $missing"
fi

echo ""
echo -e "${BOLD}controls (each mutated copy of the shipped script must be caught)${NC}"

mutate() {
  local file="$1" old="$2" new="$3"
  python3 -I -c '
import re, sys
p, old, new = sys.argv[1:4]
t = open(p).read()
pat = r"\s+".join(map(re.escape, old.split()))
n = len(re.findall(pat, t))
if n != 1:
    print(f"{n} matches", end="")
    sys.exit(3)
open(p, "w").write(re.sub(pat, lambda _: new, t))
' "$file" "$old" "$new"
}

MUT_N=0
control() {
  local label="$1" fn="$2" old="$3" new="$4" f
  MUT_N=$((MUT_N + 1))
  f="$WORK/mutant.$MUT_N.sh"
  cp "$REAL" "$f"
  local n
  if ! n="$(mutate "$f" "$old" "$new")"; then
    record "control: $label" 0 "mutation text must match the shipped script exactly once (whitespace-insensitive), found ${n:-error}: $old"
    return
  fi
  if "$fn" "$f"; then
    record "control: $label" 0 "$fn still passes on the mutant"
  else
    record "control: $label" 1
  fi
}

control "dropping default-first is detected" c_order_marker_dedupe 'apps+=("$default")' ':'
control "dropping the dedupe is detected" c_order_marker_dedupe '*" $id "*) continue ;;' '*" $id "*) : ;;'
control "a different prompt is detected" c_prompt_has_title_and_mime '--prompt="Menu ($mime)> "' '--prompt="Open with: "'
control "keeping the marker in the id is detected" c_launch_default 'id=${choice#??}' 'id=$choice'
control "stripping .desktop from flatpak ids is detected" c_flatpak_ids_pass_through 'exec gtk-launch "$id" "$file"' 'exec gtk-launch "${id%.desktop}" "$file"'
control "an unquoted file argument is detected" c_spaces_in_file_name 'exec gtk-launch "$id" "$file"' 'exec gtk-launch "$id" $file'
control "a non-zero exit on Esc is detected" c_esc_exits_zero_no_launch '--header="* = default application") || exit 0' '--header="* = default application") || exit 3'
control "a non-zero exit on empty selection is detected" c_empty_selection_exits_zero_no_launch '[ -n "$id" ] || exit 0' '[ -n "$id" ] || exit 3'
control "launching on empty selection is detected" c_empty_selection_exits_zero_no_launch '[ -n "$id" ] || exit 0' '[ -n "$id" ] || :'
control "exit 0 on an unknown MIME type is detected" c_unknown_mime_message_nonzero 'of $file" >&2 exit 1' $'of $file" >&2\nexit 0'
control "exit 0 on no associated apps is detected" c_no_apps_message_nonzero 'associated with $mime" >&2 exit 1' $'associated with $mime" >&2\nexit 0'
control "dropping LC_ALL=C is detected" c_gio_mime_runs_in_c_locale 'LC_ALL=C gio mime' 'gio mime'

NO_FZF_PATH="$(tr ':' '\n' <<<"$PATH_LINE" | grep -v -- '-fzf-' | paste -sd: -)"
if [[ -n "$(missing_tools "$NO_FZF_PATH")" ]]; then
  record "control: a runtime PATH without fzf is detected" 1
else
  record "control: a runtime PATH without fzf is detected" 0 "missing_tools did not flag fzf"
fi
if [[ -n "$(missing_tools "")" ]]; then
  record "control: an empty runtime PATH is detected" 1
else
  record "control: an empty runtime PATH is detected" 0 "missing_tools passes with an empty PATH"
fi

echo ""
echo -e "${BOLD}=== opener run string, executed the way yazi runs an opener ===${NC}"
echo ""

SPLAT="$WORK/splat.py"
cat >"$SPLAT" <<'PY'
import os, sys

ALLOWED = set(b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_=/,.+")


def cue(s):
    if s and all(c in ALLOWED for c in s):
        return s
    out = bytearray(b"'")
    for c in s:
        if c in b"'!":
            out += b"'\\" + bytes([c]) + b"'"
        else:
            out.append(c)
    return bytes(out + b"'")


def parent(p):
    if p in (b"", b"/"):
        return b""
    head = p.rstrip(b"/").rpartition(b"/")[0]
    return b"/" if p.startswith(b"/") and head == b"" else head


class Splatter:
    def __init__(self, files):
        self.files, self.tab, self.spread = files, 1, False

    def selected(self, idx):
        if idx is None:
            self.spread = True
        if self.tab != 1:
            return []
        if idx is None or idx == 0:
            return list(self.files)
        return self.files[idx - 1:idx]

    def peek(self):
        return self.cmd[self.p] if self.p < len(self.cmd) else None

    def next(self):
        c = self.peek()
        if c is not None:
            self.p += 1
        return c

    def digits(self):
        n = None
        while (c := self.peek()) is not None and 48 <= c <= 57:
            n = (n or 0) * 10 + c - 48
            self.p += 1
        return n

    def splat(self, cmd):
        self.cmd, self.p, buf = cmd, 0, bytearray()
        while (c := self.next()) is not None:
            if c == ord("%") and self.peek() is not None:
                self.visit(buf)
            else:
                buf.append(c)
        return bytes(buf)

    def many(self, buf, items, idx):
        first = True
        for item in items:
            if not first:
                buf.append(ord(" "))
            first = False
            buf += cue(item)
        if first and idx is not None:
            buf += cue(b"")

    def visit(self, buf):
        c = self.peek()
        ch = chr(c) if c is not None else ""
        if ch in ("s", "S", "d", "D"):
            self.next()
            idx = self.digits()
            files = self.selected(idx)
            self.many(buf, files if ch in "sS" else [parent(f) for f in files], idx)
        elif ch in ("h", "H"):
            self.next()
            buf += cue(b"")
        elif ch in ("y", "Y"):
            self.next()
            self.many(buf, [], self.digits())
        elif ch in ("t", "T"):
            self.next()
            old = self.tab
            self.tab = self.tab + 1 if ch == "t" else max(self.tab - 1, 0)
            if self.peek() is None:
                buf.append(ord("%"))
            else:
                self.visit(buf)
            self.tab = old
        elif ch == "%":
            buf.append(self.next())
        else:
            buf.append(ord("%"))
            if c is not None:
                buf.append(self.next())


mode, cmd, files = sys.argv[1], os.fsencode(sys.argv[2]), [os.fsencode(f) for f in sys.argv[3:]]
if mode == "splat":
    sys.stdout.buffer.write(Splatter(files).splat(cmd))
elif mode == "open":
    probe = Splatter([])
    probe.splat(cmd)
    size = max(len(files), 1) if probe.spread else 1
    for i in range(0, max(len(files), 1), size):
        sys.stdout.buffer.write(Splatter(files[i:i + size]).splat(cmd) + b"\0")
PY

RUN_STRING="$(jq -r '.openWithRun' <<<"$json")"
HELPER_BIN="$HELPER_OUT/bin/yazi-open-with"
RUN_TAIL="${RUN_STRING#"$HELPER_BIN"}"

BIN_YAZI="$WORK/yazi-bin"
mkdir -p "$BIN_YAZI"
cat >"$BIN_YAZI/argv-stub" <<'STUB'
#!/usr/bin/env bash
{ printf 'ARGV'; printf ' <%s>' "$@"; printf '\n'; } >>"$STUB_DIR/argv.log"
STUB
cat >"$BIN_YAZI/real-helper" <<STUB
#!/usr/bin/env bash
exec bash "$REAL" "\$@"
STUB
chmod +x "$BIN_YAZI/argv-stub" "$BIN_YAZI/real-helper"

FILE_BANG="$FIXDIR/dir with space/it's done! (2).txt"
touch "$FILE_BANG"

yazi_open() {
  local run="$1" target="$2" fzf="$3" cmd rc
  shift 3
  RUN_N=$((RUN_N + 1))
  R="$WORK/run.$RUN_N"
  mkdir -p "$R"
  printf '%s' "$LISTING_MAIN" >"$R/listing"
  : >"$R/rcs"
  run="$target${run#"$HELPER_BIN"}"
  while IFS= read -r -d '' cmd; do
    printf '%s\n' "$cmd" >>"$R/cmds"
    rc=0
    (
      cd "$FIXDIR" || exit 97
      unset LC_ALL
      PATH="$BIN:$PATH" STUB_DIR="$R" STUB_MIME=text/plain STUB_LISTING="$R/listing" STUB_FZF="$fzf" \
        sh -c "$cmd" </dev/null >"$R/out" 2>>"$R/err"
    ) || rc=$?
    printf '%s\n' "$rc" >>"$R/rcs"
  done < <(python3 -I "$SPLAT" open "$run" "$@")
  DETAIL="cmds=$(flat "$R/cmds") rcs=$(flat "$R/rcs") argv=$(flat "$R/argv.log") err=$(flat "$R/err") launch=$(flat "$R/launch.log")"
  return 0
}

argv_is() { [[ "$(cat "$R/argv.log" 2>/dev/null)" == "$1" ]]; }
all_rc_zero() { [[ -s "$R/rcs" ]] && ! grep -qv '^0$' "$R/rcs"; }

o_single_tricky_file() {
  yazi_open "$1" "$BIN_YAZI/argv-stub" "" "$FILE_SPACES" || return 1
  all_rc_zero && argv_is "ARGV <$FILE_SPACES>" || return 1
  yazi_open "$1" "$BIN_YAZI/argv-stub" "" "$FILE_BANG"
  all_rc_zero && argv_is "ARGV <$FILE_BANG>"
}
o_plain_file() {
  yazi_open "$1" "$BIN_YAZI/argv-stub" "" "$FILE_PLAIN"
  all_rc_zero && argv_is "ARGV <$FILE_PLAIN>"
}
o_two_selected_one_call_each() {
  yazi_open "$1" "$BIN_YAZI/argv-stub" "" "$FILE_PLAIN" "$FILE_SPACES"
  all_rc_zero && argv_is "ARGV <$FILE_PLAIN>"$'\n'"ARGV <$FILE_SPACES>"
}
o_end_to_end_real_helper() {
  yazi_open "$1" "$BIN_YAZI/real-helper" pick:3 "$FILE_SPACES"
  all_rc_zero && launch_is "LAUNCH <org.kde.kate.desktop> <$FILE_SPACES>"
}

if [[ "$RUN_STRING" == "$HELPER_BIN "* && -x "$HELPER_BIN" ]]; then
  record "opener: run string starts with the built helper's bin path" 1
else
  record "opener: run string starts with the built helper's bin path" 0 "run=$RUN_STRING helper=$HELPER_BIN"
fi

contract_detail=""
YAZI_PKG_DRV="$(jq -r '.yaziDrv' <<<"$json")"
if ! YAZI_PKG=$(nix build --no-link --print-out-paths "${YAZI_PKG_DRV}^out" 2>"$stderr_file" | head -1) || [[ -z "$YAZI_PKG" ]]; then
  contract_detail="cannot build the configured yazi package: $(grep -E 'error:' "$stderr_file" | head -3 | tr '\n' '~')"
else
  YAZI_BIN="$YAZI_PKG/bin/yazi"
  if ! grep -aq $'\x7fELF' <(head -c 4 "$YAZI_BIN"); then
    YAZI_BIN="$(sed -n 's/^exec "\(\/nix\/store\/[^"]*\/bin\/yazi\)".*/\1/p' "$YAZI_BIN" | head -1)"
  fi
  if [[ -z "$YAZI_BIN" || ! -f "$YAZI_BIN" ]]; then
    contract_detail="cannot locate the real yazi binary behind $YAZI_PKG/bin/yazi"
  elif ! grep -aFq 'run = "xdg-open %s1"' "$YAZI_BIN"; then
    contract_detail="$YAZI_BIN preset no longer contains run = \"xdg-open %s1\": the opener placeholder convention changed"
  elif grep -aFq 'xdg-open "$1"' "$YAZI_BIN" || grep -aFq 'xdg-open "$@"' "$YAZI_BIN"; then
    contract_detail="$YAZI_BIN preset uses positional shell args (xdg-open \"\$1\"/\"\$@\")"
  fi
fi
if [[ -z "$contract_detail" ]]; then
  record "contract: shipped yazi presets use %s1, not \$1/\$@" 1
else
  record "contract: shipped yazi presets use %s1, not \$1/\$@" 0 "$contract_detail"
fi

vector_fail=""
vector() {
  local cmd="$1" want="$2" got
  shift 2
  got="$(python3 -I "$SPLAT" splat "$cmd" "$@")"
  [[ "$got" == "$want" ]] || vector_fail+="[$cmd] got <$got> want <$want> "
}
vector 'ls %s' "ls 't 2/s 1' 't 2/s 2'" 't 2/s 1' 't 2/s 2'
vector 'ls %s1 %s3 %s2' "ls 't 2/s 1' '' 't 2/s 2'" 't 2/s 1' 't 2/s 2'
vector 'cd %d' "cd 't 2' 't 2'" 't 2/s 1' 't 2/s 2'
vector 'cd %d1 %d3 %d2' "cd 't 2' '' 't 2'" 't 2/s 1' 't 2/s 2'
vector 'ls %s %s2 %s' 'ls t1/s1 t1/s2 t1/s2 t1/s1 t1/s2' t1/s1 t1/s2
vector 'echo % %% %s2 %%h %d' 'echo % % t1/s2 %h t1 t1' t1/s1 t1/s2
vector 'ls %s' 'ls '
vector 'ls %s1 %s %s2' "ls ''  ''"
vector 'cd %d %d1' "cd  ''"
if [[ -z "$vector_fail" ]]; then
  record "splat model: reproduces upstream splatter.rs unix test vectors" 1
else
  record "splat model: reproduces upstream splatter.rs unix test vectors" 0 "$vector_fail"
fi

roundtrip_fail=""
for name in "$FILE_SPACES" "$FILE_BANG" "plain-name.txt" "" "a\"b\\c" $'tab\there'; do
  got="$(sh -c "printf '%s' $(python3 -I "$SPLAT" splat '%s1' "$name")")"
  [[ "$got" == "$name" ]] || roundtrip_fail+="<$name> -> <$got> "
done
if [[ -z "$roundtrip_fail" ]]; then
  record "splat model: escaped names survive sh -c unchanged" 1
else
  record "splat model: escaped names survive sh -c unchanged" 0 "$roundtrip_fail"
fi

OPENER_CASES=(
  "hovered file with spaces, quotes, \$ and ! arrives as \$1|o_single_tricky_file"
  "plain file arrives as \$1|o_plain_file"
  "two selected files: one helper call per file|o_two_selected_one_call_each"
  "end to end: real helper launches the pick for the file|o_end_to_end_real_helper"
)
for entry in "${OPENER_CASES[@]}"; do
  IFS='|' read -r label fn <<<"$entry"
  if "$fn" "$RUN_STRING"; then record "opener: $label" 1; else record "opener: $label" 0 "$DETAIL"; fi
done

echo ""
echo -e "${BOLD}controls (each wrong run-string convention must be caught)${NC}"

run_control() {
  local label="$1" fn="$2" tail="$3"
  if [[ "$RUN_TAIL" != " %s1" ]]; then
    record "control: $label" 0 "the shipped run string tail is <$RUN_TAIL>, controls assume ' %s1'"
  elif "$fn" "$HELPER_BIN $tail"; then
    record "control: $label" 0 "$fn still passes with run tail <$tail>"
  else
    record "control: $label" 1
  fi
}
run_control 'positional "$1" (yazi passes no args) is detected' o_plain_file '"$1"'
run_control 'positional "$1" breaks the end-to-end run' o_end_to_end_real_helper '"$1"'
run_control 'positional "$@" is detected' o_plain_file '"$@"'
run_control 'a double-quoted "%s1" (double escaping) is detected' o_single_tricky_file '"%s1"'
run_control 'spread %s (all files in one call) is detected' o_two_selected_one_call_each '%s'

finish
