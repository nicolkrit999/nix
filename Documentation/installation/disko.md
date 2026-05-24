# NixOS Installation Guide (with disko)

> **Prerequisite:** Change `homeManagerUser` in `flake.nix` to your chosen username before starting. Every host is forced to share the same username.

---

## Phase 1: Preparation

### 1. Download & Flash

1. **Download:** Get the **NixOS Minimal ISO** (64-bit Intel/AMD) from [nixos.org](https://nixos.org/download.html).
2. **Flash:** Use **Rufus, Balena Etcher, or similar** to write the ISO to a USB stick.
   - **Partition Scheme:** GPT
   - **Target System:** UEFI (non-CSM)
3. **BIOS:** Ensure **Secure Boot** is Disabled and BIOS is set to **UEFI** mode.

### 2. Boot & Connect

1. Insert the USB and boot your computer.
2. Select **"UEFI: [Your USB Name]"** from the boot menu.
3. Once the text console loads (`[nixos@nixos:~]$`):
   - **WiFi:** Run `sudo nmtui`, select "Activate a connection", and pick your network.
   - **Ethernet:** Should work automatically. Verify with `ping google.com`.

---

## Phase 2: Installation

### 1. Download the Config

```bash
nix-shell -p git
git clone https://github.com/nicolkrit999/nix.git
cd ~/nix
```

### 2. Identify Your Disk

```bash
lsblk -o NAME,SIZE,FSAVAIL
```

Note the disk name (e.g. `nvme0n1` for NVMe SSDs, `sda` for SATA).

### 3. Create Your Host

Copy the template to a new folder. Replace `my-computer` with your desired hostname.

```bash
cd hosts
cp -r template-host-minimal my-computer
cd my-computer
```

Edit `default.nix` and uncomment the disko import that matches your chosen option:

```nix
nixos =
  { ... }:
  {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";
    imports = [
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

      #./disko-config-btrfs.nix                      # Option A — no encryption
      #./disko-config-btrfs-luks-impermanence.nix    # Option B — LUKS + TPM
    ];
  };
```

---

## Option A: Standard (No Encryption)

### Configure the Drive

1. Copy the disko config to your host folder:
   ```bash
   cp ~/nix/hosts/template-host-minimal/disko-config-btrfs.nix ~/nix/hosts/my-computer/
   ```
2. Open it: `nano disko-config-btrfs.nix`
3. Find `device = "/dev/nvme0n1";` and change it to your actual disk.
4. Adjust the `boot` partition size (1–4 GB recommended).

### Configure Critical Variables

```bash
nano default.nix
```

- **`user`**: Change `"template-user"` to your real username (set this now — do not rename later).
- **`homeManagerSystem`**: `x86_64-linux` for Intel/AMD, `aarch64-linux` for ARM.
- **Keyboard**: Set `keyboardLayout` and `keyboardVariant` to avoid layout issues at login.

### Enable Suggested Modules

Check `template-host-minimal/default.nix` for modules with `enable = true` blocks and enable what you need. See the [denix possibilities guide](../usage/denix/possibilities.md) for descriptions.

### Install

```bash
cd ~/nix/hosts/my-computer

# Format the drive (irreversible!)
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode format ./disko-config-btrfs.nix

# Mount the drive
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode mount ./disko-config-btrfs.nix

# Generate hardware config
nixos-generate-config --no-filesystems --root /mnt --dir .

# Install
cd ~/nix
sudo nixos-install --flake .#my-computer
```

---

## Option B: Secure (LUKS + TPM 2.0)

### Configure the Drive

1. Copy the disko config to your host folder:
   ```bash
   cp ~/nix/hosts/template-host-minimal/disko-config-btrfs-luks-impermanence.nix ~/nix/hosts/my-computer/
   ```
2. Open it: `nano disko-config-btrfs-luks-impermanence.nix`
3. Find `device = "/dev/nvme0n1";` **and** `nvme0n1 = {` — change **both** to your actual disk.
4. Adjust the `boot` partition size (1–4 GB recommended).
5. Adjust the `swap` size (slightly above your RAM if you want hibernation).

### Configure Critical Variables

Same as Option A above (`user`, `homeManagerSystem`, keyboard).

### Install

```bash
cd ~/nix/hosts/my-computer

# Format the drive (you will be prompted to set a LUKS passphrase)
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode format ./disko-config-btrfs-luks-impermanence.nix

# Mount the drive (enter your LUKS passphrase)
sudo nix run --extra-experimental-features 'nix-command flakes' github:nix-community/disko -- --mode mount ./disko-config-btrfs-luks-impermanence.nix

# Generate hardware config
nixos-generate-config --no-filesystems --root /mnt --dir .

# Install
cd ~/nix
sudo nixos-install --flake .#my-computer
```

---

## Phase 3: Finish

1. Set your **root password** when prompted.
2. **Copy your config to the persistent drive before rebooting:**
   ```bash
   sudo cp -r ~/nix /mnt/etc/nix
   ```
3. `reboot` and remove the USB stick.

4. **(Option B — LUKS only):** Once booted into your new system, bind the TPM for auto-unlock:
   ```bash
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
   ```
   Re-bind after a firmware update or motherboard replacement:
   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
   ```

---

## Phase 4: Post-Install Setup

### Move Config to Home

```bash
sudo mv /etc/nix ~/nix
sudo chown -R $USER:users ~/nix
```

### (Optional) Cleanup Unused Hosts

```bash
(
  cd ~/nix || return
  printf "Enter hostnames to KEEP (space separated): "
  read -r INPUT

  if [ -z "$INPUT" ]; then
      echo "No input. Exiting."
      return
  fi

  SAFE_TO_DELETE=true
  for host in ${INPUT}; do
      if [ ! -d "hosts/$host" ]; then
          echo "Error: 'hosts/$host' not found."
          SAFE_TO_DELETE=false
      fi
  done

  if [ "$SAFE_TO_DELETE" = true ]; then
      echo "Cleaning up..."
      for dir_path in hosts/*; do
          [ -d "$dir_path" ] || continue
          dir_name=$(basename "$dir_path")

          matched=false
          for keep_name in ${INPUT}; do
              if [ "$dir_name" = "$keep_name" ]; then
                  matched=true
              fi
          done

          if [ "$matched" = false ]; then
              rm -rf "$dir_path"
          fi
      done
      echo "Done. Remaining hosts:"
      ls hosts/
  else
      echo "Aborting. No changes made."
  fi
)
```

*Example input: `my-computer` — deletes every host except this one.*

### (Optional) local-packages.nix and flatpak.nix

- `local-packages.nix`: add packages installed only on this host.
- `flatpak.nix`: add flatpak packages installed only on this host.
