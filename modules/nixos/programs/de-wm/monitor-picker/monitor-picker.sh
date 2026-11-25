# Usage: monitor-picker watch | open | mirror [TARGET_OUTPUT]
: "${MONITOR_PICKER_DECLARED:?}"
: "${XDG_RUNTIME_DIR:?}"
state_dir=$XDG_RUNTIME_DIR/monitor-picker

detect_wm() {
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    echo hyprland
  elif [[ -n ${NIRI_SOCKET:-} ]]; then
    echo niri
  elif [[ -n ${MANGO_INSTANCE_SIGNATURE:-} ]]; then
    echo mango
  else
    return 1
  fi
}

# name<TAB>second column: hyprland monitor description, niri/mango "make model serial"
list_outputs() {
  case $1 in
    hyprland) hyprctl monitors all -j | jq -r '.[] | [.name, (.description // "")] | @tsv' ;;
    niri) niri msg --json outputs | jq -r 'to_entries[] | [.key, "\(.value.make // "") \(.value.model // "") \(.value.serial // "")"] | @tsv' ;;
    mango) wlr-randr --json | jq -r '.[] | [.name, "\(.make // "") \(.model // "") \(.serial // "")"] | @tsv' ;;
  esac
}

is_declared() {
  local wm=$1 name=$2 desc=$3 d
  [[ -r $MONITOR_PICKER_DECLARED/$wm ]] || return 1
  while IFS= read -r d; do
    [[ -z $d ]] && continue
    [[ $d == "$name" || $d == "desc:$desc" ]] && return 0
    [[ -n ${desc// /} && $d == "$desc" ]] && return 0
    [[ $d == desc:* && -n ${desc// /} && $desc == "${d#desc:}"* ]] && return 0
  done <"$MONITOR_PICKER_DECLARED/$wm"
  return 1
}

open_picker() {
  local wm=$1
  mkdir -p "$state_dir"
  case $wm in
    hyprland | mango) exec nwg-displays -m "$state_dir/monitors.conf" ;;
    niri) exec nwg-displays -m "$state_dir/monitor.kdl" ;;
  esac
}

check() {
  local wm=$1 out name desc key new=() keys=()
  out=$(list_outputs "$wm") || return 0
  mkdir -p "$state_dir"
  touch "$state_dir/seen"
  while IFS=$'\t' read -r name desc; do
    [[ -z $name ]] && continue
    is_declared "$wm" "$name" "$desc" && continue
    key="$name|$desc"
    grep -qxF -- "$key" "$state_dir/seen" && continue
    new+=("$name")
    keys+=("$key")
  done <<<"$out"
  if ((${#new[@]})) && ! pgrep -x nwg-displays >/dev/null; then
    echo "monitor-picker: undeclared output(s): ${new[*]}" >&2
    printf '%s\n' "${keys[@]}" >>"$state_dir/seen"
    (open_picker "$wm") &
  fi
  return 0
}

debounce() {
  local wm=$1 _
  while read -r _; do
    while read -r -t 2 _; do :; done
    sleep 1
    check "$wm"
  done
}

wait_wm() {
  local wm
  for _ in {1..20}; do
    if wm=$(detect_wm); then
      echo "$wm"
      return 0
    fi
    sleep 1
  done
  return 1
}

watch() {
  local wm
  wm=$(wait_wm) || exit 0
  sleep 5
  check "$wm"
  case $wm in
    hyprland)
      socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - |
        grep --line-buffered '^monitoradded' | debounce "$wm"
      ;;
    *)
      udevadm monitor --udev --subsystem-match=drm |
        grep --line-buffered '^UDEV' | debounce "$wm"
      ;;
  esac
}

focused_output() {
  local wm=$1 name=""
  case $wm in
    niri) name=$(niri msg --json focused-output | jq -r '.name // empty') ;;
    mango) name=$(mmsg get all-monitors | jq -r '[.monitors[] | select(.active) | .name][0] // empty') ;;
  esac
  [[ -n $name ]] || name=$(list_outputs "$wm" | head -n1 | cut -f1)
  echo "$name"
}

mirror() {
  local wm src tgt=${1:-}
  wm=$(detect_wm) || { echo "monitor-picker: no supported compositor" >&2; exit 1; }
  if [[ $wm == hyprland ]]; then
    echo "monitor-picker: Hyprland mirrors natively, use 'monitor-picker open'" >&2
    exit 1
  fi
  src=$(focused_output "$wm")
  if [[ -z $tgt ]]; then
    tgt=$(list_outputs "$wm" | cut -f1 | grep -vxF "$src" | head -n1 || true)
  fi
  [[ -n $tgt ]] || { echo "monitor-picker: no second output to mirror onto" >&2; exit 1; }
  exec wl-mirror --fullscreen-output "$tgt" "$src"
}

case ${1:-} in
  watch) watch ;;
  open)
    wm=$(detect_wm) || { echo "monitor-picker: no supported compositor" >&2; exit 1; }
    pgrep -x nwg-displays >/dev/null && exit 0
    open_picker "$wm"
    ;;
  mirror) shift; mirror "$@" ;;
  *) echo "usage: monitor-picker watch | open | mirror [TARGET_OUTPUT]" >&2; exit 2 ;;
esac
