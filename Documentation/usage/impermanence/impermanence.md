# ❄️ Impermanence User Guide: The Immortal Root

 By mounting your root directory (`/`) as a **tmpfs** (RAM disk), every single file not explicitly saved is wiped instantly upon reboot. This keeps your OS clean, prevents "configuration drift," and ensures your system remains exactly as defined in your Nix files. 

---

## 🛠️ How it Works in This Repo

### 1. Global Persistence (`impermanence.nix`)

All standard system requirements (Machine IDs, NetworkManager connections, Bluetooth, SSH host keys, and Docker/Podman data) are already pre-configured in the global module. You do not need to manually add these for every new host. 

### 2. Host-Specific Persistence (`system.nix`)

If you have unique hardware or local services (like a specific mouse driver or a local database), you should define those inside the `nixos` block of your specific host's `system.nix` (if you have separate host files) or into `default.nix`. 


> **💡 Best Practice:** If you plan to share a fork of this repo with friends or the public, keep host-specific persistence (like personal app configs) in the host folder, while keeping generic system logic in the `modules/` folder. 
> 
> 

**Example of adding custom items in `system.nix`:**

```nix
nixos = {
  environment.persistence."/persist" = {
    directories = [ "/var/lib/my-custom-app" ]; # Folders to save
    files = [ "/etc/custom-config.conf" ];      # Individual files to save
  };
};
```

---

## 🔑 Security & Passwords

Because `/etc/shadow` (the file that stores your password) is deleted every time you turn off the computer, you **must** use a declarative password. 

1. **SOPS Integration**: This repo support `sops-nix` to securely inject your password from an encrypted file, and set it for the user and/or the root. 


2. **The Boot Race Condition**: To ensure you don't get locked out, SOPS must find your SSH decryption keys before the "invisible" RAM links are created. 


3. **The Fix**: You must point SOPS directly to the physical `/persist` path in your `system.nix`. 



**Sample required Configuration:**

```nix
# Found in hosts/nixos-desktop/system.nix
sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
sops.secrets."krit-local-password".neededForUsers = true;
```

---

## 🚚 Migrating Data (The Rsync Step)

If you are moving from a standard installation to an Impermanent one, you must manually move your "identity" files to the `/persist` drive before your first reboot.

Run these commands to sync the existing data to the persist point
- Double check with an ls or similar that the data you need is actually there
- `/var/tmp` is not needed to be synced the first time

```bash
# 1. Ensure /persist is mounted (Auto-handled if using the 'impermanence' disko profile)
# 2. Copy the essentials
# 1. Create the necessary folder structures
sudo mkdir -p /persist/etc/NetworkManager/

sudo mkdir -p /persist/var/lib/systemd/

sudo mkdir -p /persist/var/db/sudo/

sudo mkdir -p /persist/var/cache/

# 2. Copy the mandatory system files
sudo rsync -a /etc/machine-id /persist/etc/ || true

sudo rsync -a /etc/adjtime /persist/etc/ || true

sudo rsync -a /etc/nixos /persist/etc/ || true

sudo rsync -a /var/cache/fscache/ || true

sudo rsync -a /etc/ssh /persist/etc/ || true

sudo rsync -a /etc/NetworkManager/system-connections /persist/etc/NetworkManager/ || true

sudo rsync -a /var/lib/bluetooth /persist/var/lib/ || true

sudo rsync -a /var/lib/nixos /persist/var/lib/ || true

sudo rsync -a /var/lib/tailscale /persist/var/lib/ || true

sudo rsync -a /var/lib/systemd/timers /persist/var/lib/systemd/ || true

sudo rsync -a /var/lib/sddm /persist/var/lib/ || true

sudo rsync -a /var/db/sudo/lectured /persist/var/db/sudo/ || true


# 3. Copy the optional/host-specific files
sudo rsync -a /var/lib/flatpak /persist/var/lib/ || true
sudo rsync -a /var/lib/docker /persist/var/lib/ || true
sudo rsync -a /var/lib/containers /persist/var/lib/ || true
sudo rsync -a /etc/logid.cfg /persist/etc/ || true
```
---

## Current persists

### **Directories**


**`/etc/nixos`**: Stores your NixOS configuration files and flakes so you can rebuild your system after a reboot.

 
**`/etc/NetworkManager/system-connections`**: Saves your Wi-Fi passwords and wired network profiles.
 
**`/etc/ssh`**: Stores permanent SSH host keys; essential for system identity and decrypting SOPS secrets before login.

 
**`/var/cache/fscache`**: Provides a persistent cache for network filesystems like WebDAV/OwnCloud; prevents `cachefilesd.service` from failing.

 
**`/var/lib/bluetooth`**: Keeps records of all paired Bluetooth devices so you don't have to re-pair them every boot.

 
**`/var/lib/nixos`**: Tracks system state data, such as unique user/group ID mappings.

 
**`/var/lib/tailscale`**: Stores your Tailscale node identity and login state to keep your VPN connected.

 
**`/var/lib/systemd/timers`**: Remembers when scheduled tasks (like trash cleanup) last ran so they don't repeat or skip unexpectedly.


**`/var/db/sudo/lectured`**: Remembers if you have already seen the "first-time" sudo warning message.

 
**`/var/tmp`**: Stores temporary files that need to survive a reboot, unlike `/tmp` which is usually cleared.


**`/var/lib/sddm`**: Maintains state for the SDDM display manager, such as your last selected user or theme.


**`/var/lib/flatpak`**: Keeps your installed Flatpak applications and their respective data.
 
**`/var/lib/docker`**: Stores your Docker images, containers, and local volumes.


**`/var/lib/containers`**: Maintains state for Podman containers and images.



### **Files**
 
**`/etc/machine-id`**: A unique ID for your OS instance; required for system logs (journald) and network DHCP stability.


**`/etc/adjtime`**: Keeps your hardware clock (RTC) synchronized and adjusted for time drift.




---

## 🔍 How to Verify It Worked

Once you reboot, you can verify that your root is indeed running in RAM and your files are successfully linked.

### 1. Check Root Filesystem

Run `df -h /`. If the filesystem is `none` or `tmpfs`, your root is currently in RAM. 

```bash
Filesystem      Size  Used Avail Use% Mounted on
none            4.0G   16M  4.0G   1% /
```

### 2. Check the Links

Run `ls -l /etc/ssh`. You should see that your keys are actually symlinks pointing into the `/persist` folder. 

```bash
lrwxrwxrwx /etc/ssh/ssh_host_ed25519_key -> /persist/etc/ssh/ssh_host_ed25519_key
```

### 3. Check for "Leaking"

Anything you create in `/tmp` or `/etc` that isn't in your `persistence` list will **disappear** the moment you restart. This is the ultimate test of a clean system. 

---
