# NixOS Installation Guide (Manual Partitioning)

> **Dual boot prerequisite:** Boot into Windows, open "Disk Management," right-click your main Windows partition, select "Shrink Volume," and create the desired **Unallocated Space** for NixOS. Leave it completely unallocated.
>
> **Also:** Change `homeManagerUser` in `flake.nix` to your chosen username before starting.

---

## Phase 1: Preparation

### 1. Download & Flash

1. **Download:** Get the **NixOS Minimal ISO** (64-bit Intel/AMD or ARM) from [nixos.org](https://nixos.org/download.html).
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

### 2. Identify the Disk and Unallocated Space

```bash
lsblk -o NAME,SIZE,FSAVAIL
```

Look for your main disk (e.g. `nvme0n1`). Note the existing partitions and the free/unallocated space.

### 3. Partition the Drive (cfdisk)

```bash
sudo cfdisk /dev/nvme0n1  # Replace with your actual disk name
```

1. Select the **Free space** (the unallocated space you created in Windows).
2. Select **New** → set size to `1G` (or 1–4 GB — NixOS needs a large boot partition for multiple generations). Change **Type** to **EFI System**.
3. Select the remaining **Free space** again → **New** → press Enter to use the rest. Keep **Type** as **Linux filesystem**.
4. Select **Write**, type `yes`, then **Quit**.

Run `lsblk -o NAME,SIZE,FSAVAIL` again to confirm your new partition numbers (e.g. `nvme0n1p3` for EFI, `nvme0n1p4` for Linux).

---

## Option A: BTRFS (No Encryption)

### Format and Mount

Replace `nvme0n1pX` with your EFI partition and `nvme0n1pY` with your Linux partition throughout.

```bash
# Format
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1pX
sudo mkfs.btrfs -L nixos -f /dev/nvme0n1pY

# Mount temporarily and create subvolumes
sudo mount /dev/nvme0n1pY /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@persist
sudo btrfs subvolume create /mnt/@var_log
sudo btrfs subvolume create /mnt/@swap
sudo btrfs subvolume create /mnt/@snapshots
sudo btrfs subvolume create /mnt/@home_snapshots
sudo umount /mnt

# Mount subvolumes
sudo mount -o compress=zstd,noatime,subvol=@ /dev/nvme0n1pY /mnt
sudo mkdir -p /mnt/{home,nix,persist,var/log,swap,boot,.snapshots}
sudo mkdir -p /mnt/home/.snapshots

sudo mount -o compress=zstd,noatime,subvol=@home /dev/nvme0n1pY /mnt/home
sudo mount -o compress=zstd,noatime,subvol=@nix /dev/nvme0n1pY /mnt/nix
sudo mount -o compress=zstd,noatime,subvol=@persist /dev/nvme0n1pY /mnt/persist
sudo mount -o compress=zstd,noatime,subvol=@var_log /dev/nvme0n1pY /mnt/var/log
sudo mount -o compress=zstd,noatime,subvol=@snapshots /dev/nvme0n1pY /mnt/.snapshots
sudo mount -o compress=zstd,noatime,subvol=@home_snapshots /dev/nvme0n1pY /mnt/home/.snapshots
sudo mount -o noatime,subvol=@swap /dev/nvme0n1pY /mnt/swap

# Swapfile (adjust 64G to match your RAM)
sudo btrfs filesystem mkswapfile --size 64G /mnt/swap/swapfile
sudo swapon /mnt/swap/swapfile

# Boot partition
sudo mount /dev/nvme0n1pX /mnt/boot
```

### Create Your Host

```bash
cd ~/nix/hosts
cp -r template-host-minimal my-computer
cd my-computer
nano default.nix
```

Remove `inputs.disko.nixosModules.disko` and any disko-config references from the `imports` list (we partitioned manually).

Also open `~/nix/flake.nix` and remove any `.disko-config` paths from the `exclude` block.

### Configure Critical Variables

- **`user`**: Change `"template-user"` to your real username.
- **`homeManagerSystem`**: `x86_64-linux` for Intel/AMD, `aarch64-linux` for ARM.
- **Keyboard**: Set `keyboardLayout` and `keyboardVariant`.

### Generate Hardware Config & Install

```bash
# NixOS auto-detects your BTRFS mounts
sudo nixos-generate-config --root /mnt
cp /mnt/etc/nix/hardware-configuration.nix ~/nix/hosts/my-computer/

# Stage new files (Flakes ignore untracked files!)
cd ~/nix
git add hosts/my-computer/

# Install
sudo nixos-install --flake .#my-computer
```

### Finish

1. Set your **user password** when prompted. If not prompted:
   ```bash
   sudo nixos-enter
   passwd your-username
   exit
   ```
2. Set **root password** if needed (same steps, just `passwd`).
3. **Copy config to the persistent drive:**
   ```bash
   sudo cp -r ~/nix /mnt/etc/nix
   ```
4. `reboot`

---

## Option B: BTRFS + LUKS Encryption

### Format and Mount

Replace `nvme0n1pX` with your EFI partition and `nvme0n1pY` with your Linux partition.

```bash
# Format EFI
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1pX

# Create and open LUKS container
sudo cryptsetup luksFormat --type luks2 /dev/nvme0n1pY
sudo cryptsetup open /dev/nvme0n1pY cryptroot

# Format and mount LUKS volume
sudo mkfs.btrfs -L nixos -f /dev/mapper/cryptroot
sudo mount /dev/mapper/cryptroot /mnt

# Create subvolumes
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/persist
sudo btrfs subvolume create /mnt/log
sudo btrfs subvolume create /mnt/swap
sudo umount /mnt

# Mount subvolumes
sudo mount -o compress=zstd,noatime,subvol=root /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/{home,nix,persist,var/log,swap,boot}

sudo mount -o compress=zstd,noatime,subvol=home /dev/mapper/cryptroot /mnt/home
sudo mount -o compress=zstd,noatime,subvol=nix /dev/mapper/cryptroot /mnt/nix
sudo mount -o compress=zstd,noatime,subvol=persist /dev/mapper/cryptroot /mnt/persist
sudo mount -o compress=zstd,noatime,subvol=log /dev/mapper/cryptroot /mnt/var/log
sudo mount -o noatime,subvol=swap /dev/mapper/cryptroot /mnt/swap

# Swapfile (adjust size as needed)
sudo btrfs filesystem mkswapfile --size 64G /mnt/swap/swapfile
sudo swapon /mnt/swap/swapfile

# EFI partition
sudo mount /dev/nvme0n1pX /mnt/boot
```

### Create Your Host

The disko config can still be used here to generate the correct `fileSystems.*` declarations without reformatting.

```bash
cd ~/nix/hosts
cp -r template-host-minimal my-computer
cp ~/nix/hosts/template-host-minimal/disko-config-btrfs-luks-impermanence.nix ~/nix/hosts/my-computer/
```

Open the copied config and update the disk name:
```bash
nano ~/nix/hosts/my-computer/disko-config-btrfs-luks-impermanence.nix
```
Find `device = "/dev/nvme0n1";` and `nvme0n1 = {` — change **both** to your actual disk. Adjust `swap.swapfile.size` if needed.

Add it to `baseExclude` in `~/nix/flake.nix` so it is not auto-discovered:
```nix
baseExclude = [
  # ...existing entries...
  ./hosts/my-computer/disko-config-btrfs-luks-impermanence.nix
];
```

Import it in your host's `default.nix` (keep `inputs.disko.nixosModules.disko`):
```nix
nixos =
  { ... }:
  {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";
    imports = [
      inputs.disko.nixosModules.disko
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix
      ./disko-config-btrfs-luks-impermanence.nix
    ];
  };
```

> Disko reads the config to generate `fileSystems.*` — it does **not** reformat your disk.

### Configure Critical Variables

- **`user`**: Change `"template-user"` to your real username.
- **`homeManagerSystem`**: `x86_64-linux` for Intel/AMD, `aarch64-linux` for ARM.
- **Keyboard**: Set `keyboardLayout` and `keyboardVariant`.

### Generate Hardware Config & Install

```bash
# Skip auto-detection of filesystems (disko handles them)
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nix/hardware-configuration.nix ~/nix/hosts/my-computer/

# Stage new files
cd ~/nix
git add hosts/my-computer/

# Install
sudo nixos-install --flake .#my-computer
```

### Finish

1. Set your **user password** when prompted.
2. Set your **root password** if needed.
3. **Copy config to the persistent drive:**
   ```bash
   sudo cp -r ~/nix /mnt/etc/nix
   ```
4. `reboot`
5. **Bind the TPM for auto-unlock** (once booted into the new system):
   ```bash
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1pY
   ```
   Re-bind after firmware updates or motherboard replacement:
   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1pY
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1pY
   ```

---

## Post-Install Setup

### Move Config to Home

```bash
sudo mv /etc/nix ~/nix
sudo chown -R $USER:users ~/nix
```

### (Optional) local-packages.nix and flatpak.nix

- `local-packages.nix`: add packages installed only on this host.
- `flatpak.nix`: add flatpak packages installed only on this host.
