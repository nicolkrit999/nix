# Usage: <wm>-wallpaperd --wm mango|hyprland|niri KEY=KIND:PATH ...
#   KEY  = connector name | desc:<make model serial> | '*' (fallback for outputs without an entry)
#   KIND = video|image
wm=""
if [[ ${1:-} == --wm ]]; then
  wm=${2:?missing wm}
  shift 2
fi
case $wm in
  mango | hyprland | niri) ;;
  *)
    echo "wallpaperd: unknown --wm '$wm'" >&2
    exit 2
    ;;
esac

declare -A spec_kind=() spec_path=()
fb_kind="" fb_path=""
for s in "$@"; do
  key=${s%%=*}
  rest=${s#*=}
  kind=${rest%%:*}
  path=${rest#*:}
  if [[ $key == '*' ]]; then
    fb_kind=$kind
    fb_path=$path
  else
    spec_kind[$key]=$kind
    spec_path[$key]=$path
  fi
done

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/${wm}-wallpaperd-${WAYLAND_DISPLAY:-wl}.lock"
flock -n 9 || { echo "$wm-wallpaperd: already running" >&2; exit 0; }

declare -A mpv_pid=()
declare -A applied=()
declare -A attempts=()
last_cur=""
retry=0
max_attempts=10
tick=5

cleanup() {
  local p
  for p in "${mpv_pid[@]}"; do
    kill "$p" 2>/dev/null || true
  done
}
trap cleanup EXIT
trap 'exit 0' INT TERM HUP

# prints one line per enabled, non-mirror output: name<TAB>make model serial
list_outputs() {
  local fmt='def d: [(.make // ""), (.model // ""), (.serial // "")] | join(" ");'
  case $wm in
    mango)
      wlr-randr --json | jq -r "$fmt"'.[] | select(.enabled) | [.name, d] | @tsv'
      ;;
    hyprland)
      hyprctl monitors -j | jq -r "$fmt"'.[] | select((.disabled | not) and ((.mirrorOf // "none") | tostring) == "none") | [.name, d] | @tsv'
      ;;
    niri)
      niri msg -j outputs | jq -r "$fmt"'to_entries[] | select(.value.logical != null) | [.key, (.value | d)] | @tsv'
      ;;
  esac
}

# one line per possibly relevant change; ends when the stream or the compositor goes away
events() {
  case $wm in
    mango)
      mmsg watch all-monitors
      ;;
    hyprland)
      socat -u "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" - \
        | grep --line-buffered -E '^(monitoradded|monitorremoved)(v2)?>>|^configreloaded>>'
      ;;
    niri)
      niri msg -j event-stream | grep --line-buffered '^{"WorkspacesChanged"'
      ;;
  esac
}

awww_ready() {
  for _ in $(seq 50); do
    if awww query >/dev/null 2>&1; then return 0; fi
    sleep 0.2
  done
  return 1
}

stop_output() {
  local o=$1
  if [[ -n ${mpv_pid[$o]:-} ]]; then
    kill "${mpv_pid[$o]}" 2>/dev/null || true
    unset "mpv_pid[$o]"
  fi
  unset "applied[$o]"
}

start_output() {
  local o=$1 kind=$2 path=$3
  case $kind in
    video)
      mpvpaper -o "loop mute=yes panscan=1.0${WALLPAPERD_MPV_EXTRA:+ $WALLPAPERD_MPV_EXTRA}" "$o" "$path" 9>&- &
      mpv_pid[$o]=$!
      ;;
    image)
      if ! awww_ready; then
        echo "$wm-wallpaperd: awww-daemon unreachable" >&2
        return 1
      fi
      local ok=0
      for _ in 1 2 3 4 5; do
        if awww img -o "$o" "$path" 9>&-; then
          ok=1
          break
        fi
        sleep 0.5
      done
      if (( ok == 0 )); then return 1; fi
      ;;
  esac
  applied[$o]="$kind:$path"
}

# sets kind/path for output $1 with description $2; non-zero when it has no wallpaper
resolve() {
  if [[ -n ${spec_kind[$1]:-} ]]; then
    kind=${spec_kind[$1]}
    path=${spec_path[$1]}
  elif [[ -n ${spec_kind["desc:$2"]:-} ]]; then
    kind=${spec_kind["desc:$2"]}
    path=${spec_path["desc:$2"]}
  elif [[ -n $fb_kind ]]; then
    kind=$fb_kind
    path=$fb_path
  else
    return 1
  fi
}

reconcile() {
  local cur o d kind path dead=0
  if ! cur=$(list_outputs); then return 1; fi

  for o in "${!mpv_pid[@]}"; do
    if ! kill -0 "${mpv_pid[$o]}" 2>/dev/null; then
      unset "mpv_pid[$o]" "applied[$o]"
      dead=1
    fi
  done
  if [[ $cur != "$last_cur" ]]; then
    attempts=()
  elif (( retry == 0 && dead == 0 )); then
    return 0
  fi
  last_cur=$cur
  retry=0

  local -A present=() desc=()
  while IFS=$'\t' read -r o d; do
    if [[ -n $o ]]; then
      present[$o]=1
      desc[$o]=$d
    fi
  done <<<"$cur"

  for o in "${!applied[@]}"; do
    if [[ -z ${present[$o]:-} ]]; then
      stop_output "$o"
      unset "attempts[$o]"
    fi
  done
  for o in "${!present[@]}"; do
    if ! resolve "$o" "${desc[$o]}"; then continue; fi
    if [[ ${applied[$o]:-} == "$kind:$path" ]]; then continue; fi
    if (( ${attempts[$o]:-0} >= max_attempts )); then continue; fi
    stop_output "$o"
    attempts[$o]=$(( ${attempts[$o]:-0} + 1 ))
    if ! start_output "$o" "$kind" "$path"; then retry=1; fi
  done
}

compositor_alive() {
  for _ in 1 2 3; do
    if list_outputs >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

maintain() {
  local o
  for o in "${!mpv_pid[@]}"; do
    if ! kill -0 "${mpv_pid[$o]}" 2>/dev/null; then retry=1; break; fi
  done
  if (( retry )); then reconcile || true; fi
}

for _ in $(seq 50); do
  if reconcile; then break; fi
  sleep 0.2
done

while true; do
  while true; do
    if IFS= read -r -t "$tick" _; then
      # coalesce bursts, but never wait longer than ~1s in total
      deadline=$((SECONDS + 1))
      while (( SECONDS <= deadline )) && IFS= read -r -t 0.3 _; do :; done
      reconcile || true
    else
      rc=$?
      if (( rc > 128 )); then maintain; else break; fi
    fi
  done < <(exec 9>&-; events)
  if ! compositor_alive; then exit 0; fi
  sleep 1
  reconcile || true
done
