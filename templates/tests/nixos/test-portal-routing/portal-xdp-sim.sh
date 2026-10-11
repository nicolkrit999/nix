#!/usr/bin/env bash
# usage: portal-xdp-sim.sh <XDG_CURRENT_DESKTOP> <hm-share-or-/nonexistent> <system-share> <config-home> <xdp-binary> <dbus-bin-dir>
# Runs xdg-desktop-portal on a private D-Bus with no service dirs (no backend is started)
# and prints the backend it picks per interface.
set -uo pipefail
desk=$1; hm=$2; sys=$3; cfg=$4; xdp=$5; dbusbin=$6
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; mkdir -m700 "$T/rt"
cat > "$T/bus.conf" <<'X'
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><policy context="default"><allow send_destination="*" eavesdrop="true"/><allow eavesdrop="true"/><allow own="*"/></policy></busconfig>
X
env -i PATH="$dbusbin:$PATH" HOME="$T" XDG_CONFIG_HOME="$cfg" XDG_CONFIG_DIRS=/nonexistent XDG_DATA_HOME=/nonexistent \
  XDG_DATA_DIRS="$hm:$sys" XDG_RUNTIME_DIR="$T/rt" XDG_CURRENT_DESKTOP="$desk" G_MESSAGES_DEBUG=all \
  dbus-run-session --config-file="$T/bus.conf" -- timeout 6 "$xdp" --verbose 2>&1 \
  | grep -E 'Using .*\.portal for|Choosing .* via the deprecated UseIn' \
  | sed -E 's/^XDP: //; s/org\.freedesktop\.impl\.portal\.//; s/.*WARNING \*\*: [0-9:.]+ //' || true
