#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # DP_* globals are the library output
# Disk planning library for the clone installer. Source it, do not execute it.
#
# Part 1 (dp_*): pure / read-only. They only read partition tables (sfdisk --json,
#   blkid -p, lsblk) and never write.
# Part 2 (apply_*): the only functions that change a disk. They go through dp_run,
#   so DRY_RUN=1 only prints the command. apply_partition_* needs only sgdisk;
#   apply_format_mount runs mkfs/cryptsetup/mount.
#
# Safety rules (all enforced here, not by the caller):
#   - INSTALLER_TEST=1 accepts only regular files, otherwise only block devices.
#   - A disk holding a mount (or swap, or a holder of one) of the running system is refused.
#   - Windows/other-OS/unknown disks are wiped only with the explicit ack "no-windows-wipe".
#   - Free-space mode creates new partitions inside the largest free block only and
#     verifies afterwards that every pre-existing partition is byte-identical in the table.
#   - No ntfsresize, ever: a too-small free block means "shrink it in Windows first".
#
# Layout values (labels, subvolumes, tmpfs size) come from layout.nix via dp_layout_load.

DP_ESP_GIB=${DP_ESP_GIB:-4}
DP_MIN_ROOT_GIB=${DP_MIN_ROOT_GIB:-64}
DP_ALIGN_BYTES=1048576

DP_GUID_EFI=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
DP_GUID_MSR=e3c9e316-0b5c-4db8-817d-f92df00215ae
DP_GUID_MSDATA=ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
DP_GUID_WINRE=de94bba4-06d1-4d40-a16a-bfd50179d6ac
DP_GUID_LINUX=0fc63daf-8483-4772-8e79-3d69d8477de4
# Other Linux-ish types: swap, LVM, RAID, root/home/srv/var/xbootldr, LUKS.
DP_LINUX_GUIDS="$DP_GUID_LINUX 0657fd6d-a4ab-43c4-84e5-0933c84b4f4f e6d6d379-f507-44c2-a23c-238f2a3df928 a19d880f-05fc-4d3b-a006-743f0f84911e 4f68bce3-e8cd-4db1-96e7-fbcaf984b709 933ac7e1-2eb4-4f13-b844-0e14e2aef915 3b8f8425-20e0-4f3b-907f-1a25a76f98e8 4d21b016-b534-45c2-a9fb-5c16e091fd2d bc13c2ff-59e6-4262-a352-b275fd6f7172 ca7d7ccb-63ed-4c53-861c-1742536059cc"

DRY_RUN=${DRY_RUN:-0}
DP_REASON=""

dp_msg() { printf '%s\n' "$*" >&2; }

# Every mutating command goes through here. DP_CMDLOG (optional) records them.
dp_run() {
  if [[ -n ${DP_CMDLOG:-} ]]; then
    printf '%q ' "$@" >>"$DP_CMDLOG"
    printf '\n' >>"$DP_CMDLOG"
  fi
  if ((DRY_RUN)); then
    printf '+ [dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# Like dp_run, but feeds a secret to stdin; the secret is never printed or logged.
dp_run_secret() {
  local secret=$1
  shift
  if [[ -n ${DP_CMDLOG:-} ]]; then
    printf '%q ' "$@" >>"$DP_CMDLOG"
    printf '(stdin: secret)\n' >>"$DP_CMDLOG"
  fi
  if ((DRY_RUN)); then
    printf '+ [dry-run] (secret on stdin)'
    printf ' %q' "$@"
    printf '\n'
  else
    printf '%s' "$secret" | "$@"
  fi
}

# ---------------------------------------------------------------------------
# layout.nix (single source of truth)
# ---------------------------------------------------------------------------

# dp_layout_load <path-to-layout.nix>
dp_layout_load() {
  local file=$1 json
  [[ -r $file ]] || {
    DP_REASON="layout file not readable: $file"
    return 1
  }
  json=$(nix eval --json -f "$file") || {
    DP_REASON="nix eval of $file failed"
    return 1
  }
  DP_ESP_LABEL=$(jq -er .espLabel <<<"$json")
  DP_BTRFS_LABEL=$(jq -er .btrfsLabel <<<"$json")
  DP_LUKS_PARTLABEL=$(jq -er .luksPartLabel <<<"$json")
  DP_LUKS_MAPPER=$(jq -er .luksMapperName <<<"$json")
  DP_TMPFS_SIZE=$(jq -er .rootTmpfsSize <<<"$json")
  DP_SV_PERSIST=$(jq -er .subvolumes.persist <<<"$json")
  DP_SV_HOME=$(jq -er .subvolumes.home <<<"$json")
  DP_SV_NIX=$(jq -er .subvolumes.nix <<<"$json")
  DP_SV_LOG=$(jq -er .subvolumes.log <<<"$json")
}

# ---------------------------------------------------------------------------
# Disk access guards
# ---------------------------------------------------------------------------

# dp_assert_disk_allowed <disk>: file-only in test mode, block-device-only otherwise.
dp_assert_disk_allowed() {
  local disk=$1
  if [[ ${INSTALLER_TEST:-0} == 1 ]]; then
    if [[ -b $disk ]]; then
      DP_REASON="INSTALLER_TEST=1: refusing block device $disk"
      return 1
    fi
    if [[ ! -f $disk ]]; then
      DP_REASON="INSTALLER_TEST=1: $disk is not a regular file"
      return 1
    fi
  else
    if [[ ! -b $disk ]]; then
      DP_REASON="$disk is not a block device"
      return 1
    fi
  fi
  return 0
}

# dp_disk_in_use <disk>: 0 when the disk (or a child / holder) is mounted or swapped.
dp_disk_in_use() {
  local disk=$1 out
  if [[ -f $disk ]]; then
    # Test images: a test can declare a disk as busy.
    case " ${INSTALLER_FAKE_INUSE:-} " in *" $disk "*) return 0 ;; esac
    return 1
  fi
  out=$(lsblk -nrpo MOUNTPOINTS "$disk" 2>/dev/null) || return 0
  [[ -n ${out//[[:space:]]/} ]]
}

dp_disk_bytes() {
  local disk=$1
  if [[ -f $disk ]]; then
    stat -c %s -- "$disk"
  else
    blockdev --getsize64 "$disk"
  fi
}

# dp_list_disks: one device path per line.
dp_list_disks() {
  if [[ ${INSTALLER_TEST:-0} == 1 ]]; then
    local d
    for d in ${INSTALLER_TEST_DISKS:-}; do printf '%s\n' "$d"; done
    return 0
  fi
  lsblk -dnpo NAME,TYPE,RO | awk '$2 == "disk" && $3 == 0 { print $1 }'
}

# dp_part_node <disk> <n>
dp_part_node() {
  local disk=$1 n=$2
  if [[ $disk =~ [0-9]$ ]]; then
    printf '%sp%s\n' "$disk" "$n"
  else
    printf '%s%s\n' "$disk" "$n"
  fi
}

# ---------------------------------------------------------------------------
# Partition table reading
# ---------------------------------------------------------------------------

dp_json() {
  sfdisk --json -- "$1" 2>/dev/null || true
}

# dp_table_label <disk>: gpt | dos | "" (no table)
dp_table_label() {
  local j
  j=$(dp_json "$1")
  [[ -n $j ]] || return 0
  jq -r '.partitiontable.label // empty' <<<"$j"
}

# dp_partitions <disk>: TSV "number start size type name" (type lower-cased).
dp_partitions() {
  local j
  j=$(dp_json "$1")
  [[ -n $j ]] || return 0
  jq -r '
    (.partitiontable.partitions // [])[]
    | [ (.node | capture("(?<n>[0-9]+)$").n), .start, .size,
        (.type | ascii_downcase), (.name // "") ]
    | @tsv' <<<"$j"
}

# dp_snapshot <disk>: identity of every partition, for before/after comparison.
dp_snapshot() {
  local j
  j=$(dp_json "$1")
  [[ -n $j ]] || return 0
  jq -r '
    (.partitiontable.partitions // [])
    | sort_by(.start)[]
    | [ .start, .size, (.type | ascii_downcase), (.uuid // ""), (.name // "") ]
    | @tsv' <<<"$j"
}

# dp_classify <disk>: empty | free-space | windows | other-os | unknown
# Priority windows > other-os > unknown. "free-space" is a disk that holds partitions
# but none of them identify an OS (e.g. only an ESP) and that has room for an install.
dp_classify() {
  local disk=$1 j fs class need
  j=$(dp_json "$disk")
  if [[ -z $j ]]; then
    fs=$(blkid -p -o value -s TYPE -- "$disk" 2>/dev/null || true)
    if [[ -n $fs ]]; then
      echo unknown
    else
      echo empty
    fi
    return 0
  fi
  class=$(jq -r \
    --arg msr "$DP_GUID_MSR" --arg msd "$DP_GUID_MSDATA" --arg re "$DP_GUID_WINRE" \
    --arg linux "$DP_LINUX_GUIDS" '
    (.partitiontable.label) as $label
    | (.partitiontable.partitions // []) as $p
    | ($p | map(.type | ascii_downcase)) as $t
    | ($linux | split(" ")) as $lin
    | if ($p | length) == 0 then "empty"
      elif $label == "gpt" then
        if any($t[]; . == $msr or . == $msd or . == $re) then "windows"
        elif any($t[]; . as $x | $lin | index($x)) then "other-os"
        else "none" end
      elif $label == "dos" then
        if any($t[]; . == "7" or . == "27" or . == "b" or . == "c" or . == "e") then "windows"
        elif any($t[]; . == "83" or . == "82" or . == "8e" or . == "fd" or . == "a5" or . == "a6" or . == "a8") then "other-os"
        else "none" end
      else "unknown" end' <<<"$j")
  if [[ $class == none ]]; then
    need=$(((DP_ESP_GIB + DP_MIN_ROOT_GIB) * 1073741824))
    free=$(dp_free_bytes "$disk")
    class=unknown
    if [[ $(dp_table_label "$disk") == gpt && $free -ge $need ]]; then
      class="free-space"
    fi
  fi
  echo "$class"
}

# dp_largest_free <disk>: "start_sector size_sectors sector_size" of the largest
# 1 MiB-aligned free block, or "0 0 <ss>" when none.
dp_largest_free() {
  local disk=$1 j last_override
  j=$(dp_json "$disk")
  if [[ -z $j ]]; then
    # No table: the whole disk minus the first MiB and a GPT tail, aligned down to 1 MiB.
    local total
    total=$(dp_disk_bytes "$disk")
    echo "2048 $(((total / DP_ALIGN_BYTES - 2) * DP_ALIGN_BYTES / 512)) 512"
    return 0
  fi
  last_override=$(($(dp_disk_bytes "$disk") / 512 - 1))
  jq -r --argjson align "$DP_ALIGN_BYTES" --argjson lastov "$last_override" '
    .partitiontable as $t
    | ($t.sectorsize // 512) as $ss
    | ($align / $ss) as $al
    | ($t.firstlba // 2048) as $first
    | ($t.lastlba // $lastov) as $last
    | def alignup: (. + $al - 1) / $al | floor * $al;
      def aligndown: . / $al | floor * $al;
    (($t.partitions // []) | sort_by(.start)) as $s
    | reduce ($s[], { start: ($last + 1), size: 0 }) as $x
        ({ cur: ($first | alignup), best: { start: 0, size: 0 } };
         (($x.start | aligndown) - .cur) as $gap
         | (if $gap > .best.size then .best = { start: .cur, size: $gap } else . end)
         | .cur = ([.cur, (($x.start + $x.size) | alignup)] | max))
    | .best as $b
    | "\($b.start) \($b.size) \($ss)"' <<<"$j"
}

# dp_free_bytes <disk>
dp_free_bytes() {
  local s z ss
  read -r s z ss <<<"$(dp_largest_free "$1")"
  : "$s"
  echo $((z * ss))
}

# dp_has_windows_esp <disk>: an EFI partition next to Windows partitions (MSR/MS data/WinRE).
# A mounted-ESP probe for EFI/Microsoft is not done here (it would need a mount);
# the install flow additionally shows the ESP to the user.
dp_has_windows_esp() {
  local disk=$1
  [[ $(dp_table_label "$disk") == gpt ]] || return 1
  [[ $(dp_classify "$disk") == windows ]] || return 1
  dp_partitions "$disk" | awk -F'\t' -v efi="$DP_GUID_EFI" '$4 == efi { f = 1 } END { exit !f }'
}

# dp_status_line <disk>: human status for the disk table.
dp_status_line() {
  local disk=$1 class free
  class=$(dp_classify "$disk")
  free=$(dp_free_bytes "$disk")
  printf '%s, largest free block %s GiB' "$class" "$((free / 1073741824))"
}

# ---------------------------------------------------------------------------
# Mode checks and plans (read-only)
# ---------------------------------------------------------------------------

# dp_wipe_allowed <disk> <ack>: whole-disk wipe policy.
dp_wipe_allowed() {
  local disk=$1 ack=${2:-} class
  dp_assert_disk_allowed "$disk" || return 1
  if dp_disk_in_use "$disk"; then
    DP_REASON="$disk holds mounts of the running system"
    return 1
  fi
  class=$(dp_classify "$disk")
  case $class in
    empty | free-space) return 0 ;;
    windows | other-os | unknown)
      if [[ $ack == no-windows-wipe ]]; then
        return 0
      fi
      DP_REASON="$disk is classified '$class'; wiping it needs the explicit choice 'no Windows, wipe'"
      return 1
      ;;
  esac
  DP_REASON="unclassifiable disk $disk"
  return 1
}

# dp_free_space_check <disk>: precondition of free-space mode.
dp_free_space_check() {
  local disk=$1 need_gib free_bytes need_bytes
  dp_assert_disk_allowed "$disk" || return 1
  if dp_disk_in_use "$disk"; then
    DP_REASON="$disk holds mounts of the running system"
    return 1
  fi
  if [[ $(dp_table_label "$disk") != gpt ]]; then
    DP_REASON="free-space mode needs a GPT disk (this one is '$(dp_table_label "$disk")')"
    return 1
  fi
  if ! dp_has_windows_esp "$disk"; then
    DP_REASON="no Windows ESP found on $disk: free-space mode only installs next to an existing Windows"
    return 1
  fi
  need_gib=$((DP_ESP_GIB + DP_MIN_ROOT_GIB))
  need_bytes=$((need_gib * 1073741824))
  free_bytes=$(dp_free_bytes "$disk")
  if ((free_bytes < need_bytes)); then
    DP_REASON="largest free block on $disk is $((free_bytes / 1073741824)) GiB, need at least ${need_gib} GiB (ESP ${DP_ESP_GIB} GiB + ${DP_MIN_ROOT_GIB} GiB root).
Shrink the Windows partition in Windows first: Disk Management -> right-click the big NTFS volume -> Shrink Volume (leave the freed space unallocated; also turn off Fast Startup and BitLocker first). The installer never resizes NTFS."
    return 1
  fi
  return 0
}

# dp_next_partnum <disk>: highest existing number + 1 (1 on an empty table).
dp_next_partnum() {
  local max
  max=$(dp_partitions "$1" | awk -F'\t' 'BEGIN { m = 0 } $1 + 0 > m { m = $1 + 0 } END { print m }')
  echo $((max + 1))
}

# dp_plan <disk> <whole|free> <luks:0|1>
# Sets DP_PLAN_* globals; prints nothing. All sectors are in units of DP_PLAN_SS bytes.
dp_plan() {
  local disk=$1 mode=$2 luks=$3 fs fs_start fs_size ss esp_sectors n
  DP_PLAN_DISK=$disk
  DP_PLAN_MODE=$mode
  DP_PLAN_LUKS=$luks
  case $mode in
    whole)
      ss=512
      [[ -f $disk ]] || ss=$(blockdev --getss "$disk")
      DP_PLAN_SS=$ss
      DP_PLAN_ESP_START=$((DP_ALIGN_BYTES / ss))
      esp_sectors=$((DP_ESP_GIB * 1073741824 / ss))
      DP_PLAN_ESP_END=$((DP_PLAN_ESP_START + esp_sectors - 1))
      DP_PLAN_ROOT_START=$((DP_PLAN_ESP_END + 1))
      DP_PLAN_ROOT_END=0 # 0 = end of disk for sgdisk
      DP_PLAN_ESP_NUM=1
      DP_PLAN_ROOT_NUM=2
      ;;
    free)
      dp_free_space_check "$disk" || return 1
      read -r fs_start fs_size ss <<<"$(dp_largest_free "$disk")"
      DP_PLAN_SS=$ss
      esp_sectors=$((DP_ESP_GIB * 1073741824 / ss))
      DP_PLAN_ESP_START=$fs_start
      DP_PLAN_ESP_END=$((fs_start + esp_sectors - 1))
      DP_PLAN_ROOT_START=$((DP_PLAN_ESP_END + 1))
      DP_PLAN_ROOT_END=$((fs_start + fs_size - 1))
      n=$(dp_next_partnum "$disk")
      DP_PLAN_ESP_NUM=$n
      DP_PLAN_ROOT_NUM=$((n + 1))
      ;;
    *)
      DP_REASON="unknown mode '$mode'"
      return 1
      ;;
  esac
  DP_PLAN_ESP_NODE=$(dp_part_node "$disk" "$DP_PLAN_ESP_NUM")
  DP_PLAN_ROOT_NODE=$(dp_part_node "$disk" "$DP_PLAN_ROOT_NUM")
  if ((luks)); then
    DP_PLAN_ROOT_TYPE=8309
    DP_PLAN_ROOT_NAME=$DP_LUKS_PARTLABEL
  else
    DP_PLAN_ROOT_TYPE=8300
    DP_PLAN_ROOT_NAME=$DP_BTRFS_LABEL
  fi
  return 0
}

# dp_plan_describe: human summary of the current DP_PLAN_*.
dp_plan_describe() {
  local ss=$DP_PLAN_SS root_end_txt
  if ((DP_PLAN_ROOT_END == 0)); then root_end_txt="end of disk"; else root_end_txt="sector $DP_PLAN_ROOT_END"; fi
  cat <<EOF
Disk:   $DP_PLAN_DISK (mode: $DP_PLAN_MODE, sector size $ss)
New partition $DP_PLAN_ESP_NUM  ESP  type EFI  name '$DP_ESP_LABEL'  sectors $DP_PLAN_ESP_START..$DP_PLAN_ESP_END (${DP_ESP_GIB} GiB, FAT32 label $DP_ESP_LABEL)
New partition $DP_PLAN_ROOT_NUM  ROOT type $DP_PLAN_ROOT_TYPE  name '$DP_PLAN_ROOT_NAME'  sectors $DP_PLAN_ROOT_START..$root_end_txt$( ((DP_PLAN_LUKS)) && echo " (LUKS2 -> btrfs '$DP_BTRFS_LABEL')" || echo " (btrfs '$DP_BTRFS_LABEL')")
EOF
  if [[ $DP_PLAN_MODE == free ]]; then
    echo "Existing partitions (kept untouched, incl. the Windows ESP):"
    dp_partitions "$DP_PLAN_DISK" | awk -F'\t' '{ printf "  %s: start %s size %s type %s %s\n", $1, $2, $3, $4, $5 }'
  else
    echo "WHOLE DISK: every existing partition and all data on it is destroyed."
  fi
}

# ---------------------------------------------------------------------------
# apply_* (the only mutating functions)
# ---------------------------------------------------------------------------

# apply_partition: writes the partition table for the current DP_PLAN_*.
# Free mode: only adds the two new partitions and verifies that the existing ones are identical.
apply_partition() {
  local disk=$DP_PLAN_DISK before after
  dp_assert_disk_allowed "$disk" || return 1
  if dp_disk_in_use "$disk"; then
    DP_REASON="$disk holds mounts of the running system"
    return 1
  fi
  local esp_end=$DP_PLAN_ESP_END root_end=$DP_PLAN_ROOT_END
  case $DP_PLAN_MODE in
    whole)
      dp_run sgdisk --zap-all -- "$disk" || return 1
      dp_run sgdisk -o -- "$disk" || return 1
      ;;
    free)
      before=$(dp_snapshot "$disk")
      ;;
  esac
  dp_run sgdisk \
    -n "${DP_PLAN_ESP_NUM}:${DP_PLAN_ESP_START}:${esp_end}" \
    -t "${DP_PLAN_ESP_NUM}:ef00" \
    -c "${DP_PLAN_ESP_NUM}:${DP_ESP_LABEL}" \
    -n "${DP_PLAN_ROOT_NUM}:${DP_PLAN_ROOT_START}:${root_end}" \
    -t "${DP_PLAN_ROOT_NUM}:${DP_PLAN_ROOT_TYPE}" \
    -c "${DP_PLAN_ROOT_NUM}:${DP_PLAN_ROOT_NAME}" \
    -- "$disk" || return 1
  if [[ $DP_PLAN_MODE == free ]] && ((!DRY_RUN)); then
    after=$(dp_snapshot "$disk")
    # Every pre-existing partition line must still be present, unchanged.
    if ! comm -23 <(sort <<<"$before") <(sort <<<"$after") | awk 'END { exit NR > 0 }'; then
      DP_REASON="existing partitions changed during free-space partitioning of $disk"
      return 1
    fi
  fi
  return 0
}

# apply_format_mount <root> <luks-passphrase-or-empty>
# Formats the two new partitions and mounts the target tree under <root>:
# tmpfs /, btrfs subvolumes @persist @home @nix @log, ESP at /boot.
apply_format_mount() {
  local root=$1 pass=${2:-} dev top
  dp_run udevadm settle || true
  dp_run partprobe "$DP_PLAN_DISK" || true
  dp_run wipefs --all "$DP_PLAN_ESP_NODE"
  dp_run wipefs --all "$DP_PLAN_ROOT_NODE"
  dp_run mkfs.vfat -F 32 -n "$DP_ESP_LABEL" "$DP_PLAN_ESP_NODE"
  if ((DP_PLAN_LUKS)); then
    ((DRY_RUN)) || [[ -n $pass ]] || {
      DP_REASON="LUKS host but empty passphrase"
      return 1
    }
    dp_run_secret "$pass" cryptsetup luksFormat --type luks2 --batch-mode --key-file=- "$DP_PLAN_ROOT_NODE"
    dp_run_secret "$pass" cryptsetup open --key-file=- "$DP_PLAN_ROOT_NODE" "$DP_LUKS_MAPPER"
    dev=/dev/mapper/$DP_LUKS_MAPPER
  else
    dev=$DP_PLAN_ROOT_NODE
  fi
  dp_run mkfs.btrfs -f -L "$DP_BTRFS_LABEL" "$dev"
  top=${DP_TOP_MOUNT:-$root.btrfs-top}
  dp_run mkdir -p "$top"
  dp_run mount "$dev" "$top"
  dp_run btrfs subvolume create "$top/$DP_SV_PERSIST"
  dp_run btrfs subvolume create "$top/$DP_SV_HOME"
  dp_run btrfs subvolume create "$top/$DP_SV_NIX"
  dp_run btrfs subvolume create "$top/$DP_SV_LOG"
  dp_run umount "$top"
  dp_run mkdir -p "$root"
  dp_run mount -t tmpfs -o "size=${DP_TMPFS_SIZE},mode=755" none "$root"
  dp_run mkdir -p "$root/persist" "$root/home" "$root/nix" "$root/var/log" "$root/boot"
  dp_run mount -o "subvol=${DP_SV_PERSIST},compress=zstd,noatime" "$dev" "$root/persist"
  dp_run mount -o "subvol=${DP_SV_HOME},compress=zstd,noatime" "$dev" "$root/home"
  dp_run mount -o "subvol=${DP_SV_NIX},compress=zstd,noatime" "$dev" "$root/nix"
  dp_run mount -o "subvol=${DP_SV_LOG},compress=zstd,noatime" "$dev" "$root/var/log"
  dp_run mount -o fmask=0022,dmask=0022 "$DP_PLAN_ESP_NODE" "$root/boot"
}
