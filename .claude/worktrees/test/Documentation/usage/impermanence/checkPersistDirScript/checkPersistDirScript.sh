echo "--- PERSISTENCE VERIFICATION REPORT ---" > ~/Downloads/persistence_check.txt
echo "Date: $(date)" >> ~/Downloads/persistence_check.txt
echo "" >> ~/Downloads/persistence_check.txt

# List of all directories and files from your config
items=(
  "/etc/machine-id"
  "/etc/adjtime"
  "/etc/logid.cfg"
  "/etc/nixos"
  "/etc/NetworkManager/system-connections"
  "/etc/ssh"
  "/var/lib/bluetooth"
  "/var/lib/nixos"
  "/var/lib/tailscale"
  "/var/lib/systemd/timers"
  "/var/db/sudo/lectured"
  "/var/tmp"
  "/var/lib/sddm"
  "/var/lib/flatpak"
  "/var/lib/docker"
  "/var/lib/containers"
)

for item in "${items[@]}"; do
  if [ -e "$item" ]; then
    # Show if it's a symlink or a mount point
    status=$(ls -ld "$item")
    echo "[OK] $status" >> ~/Downloads/persistence_check.txt
  else
    echo "[MISSING] $item" >> ~/Downloads/persistence_check.txt
  fi
done

echo "" >> ~/Downloads/persistence_check.txt
echo "--- PHYSICAL STORAGE CHECK (/persist) ---" >> ~/Downloads/persistence_check.txt
sudo tree -apugL 3 /persist >> ~/Downloads/persistence_check.txt

echo "Report generated at ~/Downloads/persistence_check.txt"
