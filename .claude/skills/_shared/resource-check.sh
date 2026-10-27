#!/usr/bin/env bash
# Hardware-based resource budget for heavy jobs. Never keys on hostname: it measures
# cores, available RAM, load and /tmp headroom, then prints a tier plus caps with
# generous headroom. Read-only, instant, no nix evaluation (so it adds no load).
# Linux: /proc. Darwin: sysctl/vm_stat. Fallback: `nix run nixpkgs#coreutils -- nproc`
# (runs from the store, nothing lands in PATH until GC).
set -u

gb() { awk -v k="$1" 'BEGIN { printf "%d", k / 1048576 }'; }

if [ -r /proc/meminfo ]; then
  cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
  mem_total_gb=$(gb "$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)")
  mem_avail_gb=$(gb "$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)")
  load1=$(awk '{print $1}' /proc/loadavg)
  tmp_free_gb=$(df -Pk /tmp 2>/dev/null | awk 'NR==2 {printf "%d", $4/1048576}')
elif command -v sysctl >/dev/null 2>&1; then
  cores=$(sysctl -n hw.ncpu)
  mem_total_gb=$(gb "$(( $(sysctl -n hw.memsize) / 1024 ))")
  page=$(sysctl -n hw.pagesize)
  free_pages=$(vm_stat | awk '/Pages (free|inactive|speculative)/ {gsub("\\.","",$NF); s+=$NF} END {print s+0}')
  mem_avail_gb=$(gb "$(( free_pages * page / 1024 ))")
  load1=$(sysctl -n vm.loadavg | awk '{print $2}')
  tmp_free_gb=$(df -Pk /tmp | awk 'NR==2 {printf "%d", $4/1048576}')
else
  cores=$(nix run nixpkgs#coreutils -- nproc 2>/dev/null || echo 2)
  mem_total_gb=8; mem_avail_gb=4; load1=1; tmp_free_gb=1
fi

# Headroom: keep max(2, 25%) of the cores and max(4 GB, 25%) of total RAM free,
# and subtract the current load so a busy machine gets a smaller budget.
reserve_cores=$(( cores / 4 > 2 ? cores / 4 : 2 ))
busy=$(awk -v l="$load1" 'BEGIN { printf "%d", l + 0.5 }')
usable_cores=$(( cores - reserve_cores - busy ))
[ "$usable_cores" -lt 1 ] && usable_cores=1
reserve_mem=$(( mem_total_gb / 4 > 4 ? mem_total_gb / 4 : 4 ))
usable_mem=$(( mem_avail_gb - reserve_mem ))
[ "$usable_mem" -lt 1 ] && usable_mem=1

# A full host evaluation peaks around 8 GB; parallel agents each may run one.
by_mem=$(( usable_mem / 8 ))
by_cpu=$(( usable_cores / 2 ))
agents=$(( by_mem < by_cpu ? by_mem : by_cpu ))
[ "$agents" -lt 1 ] && agents=1
[ "$agents" -gt 8 ] && agents=8

# nix -j and --cores per build: few jobs, cores split between them.
nix_jobs=$(( usable_cores / 4 )); [ "$nix_jobs" -lt 1 ] && nix_jobs=1; [ "$nix_jobs" -gt 4 ] && nix_jobs=4
nix_cores=$(( usable_cores / nix_jobs )); [ "$nix_cores" -lt 1 ] && nix_cores=1

# The --parallel suite peaked at ~52 GB (unit) / 59 GB (system) and /tmp was a 4 GB tmpfs.
if [ "$usable_mem" -ge 64 ] && [ "$usable_cores" -ge 8 ] && [ "$tmp_free_gb" -ge 3 ]; then
  parallel_tests=yes
else
  parallel_tests=no
fi

if [ "$agents" -ge 4 ]; then tier=heavy
elif [ "$agents" -ge 2 ]; then tier=medium
else tier=light; fi

cat <<OUT
cores=$cores mem_total_gb=$mem_total_gb mem_avail_gb=$mem_avail_gb load1=$load1 tmp_free_gb=$tmp_free_gb
tier=$tier
max_parallel_agents=$agents
nix_flags=-j$nix_jobs --cores $nix_cores
run_tests_parallel=$parallel_tests
OUT
