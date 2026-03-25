# Manual NixOS Installation — BTRFS + LUKS Encryption (Dual Boot)

Target hardware:
- **Disk:** 4 TB PCIe 4.0 NVMe (~3,726 GiB actual)
- **RAM:** 32 GB DDR5 9600 MT/s
- **Setup:** Dual boot with Windows (Windows installed first)

---

## Partition Layout Reference

```
┌──────────────────────────────────────────────────────────────────┐
│ NVMe SSD (~3,726 GiB)                                            │
├────────────────────────────────┬─────────────────────────────────┤
│ Windows (NTFS)                 │ NixOS                           │
│ ~1,862 GiB                     │ ~1,864 GiB                      │
│                                ├──────────┬──────────────────────┤
│ [Created by Windows installer] │ EFI/boot │ LUKS container       │
│                                │  4 GiB   │  ~1,858 GiB          │
│                                │  vfat    │                      │
│                                │          │ ┌──────────────────┐ │
│                                │          │ │ BTRFS (cryptroot)│ │
│                                │          │ ├──────────────────┤ │
│                                │          │ │ subvol: root  /  │ │
│                                │          │ │ subvol: home     │ │
│                                │          │ │ subvol: nix      │ │
│                                │          │ │ subvol: persist  │ │
│                                │          │ │ subvol: log      │ │
│                                │          │ │ subvol: swap     │ │
│                                │          │ │   swapfile: 32G  │ │
│                                │          │ └──────────────────┘ │
└────────────────────────────────┴──────────┴──────────────────────┘
```

**Swap rationale:** 32 GiB = exact RAM size. Enables full hibernation (suspend-to-disk).
On a 1,858 GiB Linux partition this is 1.7% of available space — essentially free.

---

## Phase 0: Prepare Windows

### How much to shrink

Windows Disk Management shows sizes in **MB**. In the "Enter the amount of space to shrink in MB"
field, enter:

```
1,906,000 MB  (≈ 1,862 GiB — your NixOS half of the disk)
```

> **Why not a power-of-2 size?**
> Powers of 2 matter for RAM (cache lines, page sizes) and internal filesystem structures, but
> not for OS partition boundaries. Modern partition tools align partitions to 1 MiB boundaries
> automatically, which is all that matters for performance. A ~50/50 split on a 4 TB drive
> means ~1,862 GiB each — that is the most balanced option.
>
> If you want Windows to have a clean 2,048 GiB (2 TiB — a true power of 2), shrink by
> **1,779,000 MB** instead. This gives NixOS ~1,678 GiB and Windows exactly 2 TiB.
> Choose based on whether you prefer balance or a round Windows partition.

Steps:
1. Boot into Windows.
2. Right-click Start → **Disk Management**.
3. Right-click your main `C:` partition → **Shrink Volume**.
4. Enter `1906000` (or `1779000` for the 2 TiB Windows option).
5. Click **Shrink**. Leave the resulting space as **Unallocated** — do not format it.
6. Shut down and boot the NixOS minimal ISO.

---

## Phase 1: Boot the NixOS ISO

1. Download the **NixOS Minimal ISO** from [nixos.org](https://nixos.org/download).
2. Flash to USB with Rufus / Balena Etcher (GPT, UEFI).
3. In BIOS: disable Secure Boot, set UEFI mode.
4. Boot into the USB. Once at `[nixos@nixos:~]$`:
   - WiFi: `sudo nmtui` → Activate a connection
   - Ethernet: auto, verify with `ping nixos.org`

---

## Phase 2: Download the Config

```bash
nix-shell -p git
git clone https://github.com/<your-repo>/nix.git
cd ~/nix
```

---

## Phase 3: Identify Your Disk

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

Look for your NVMe SSD (e.g. `nvme0n1`, ~4 TB total). You will see:
- Existing Windows partitions (Recovery, EFI, MSR, NTFS C:)
- A block of **unallocated space** at the end — this is your NixOS space

Note the exact disk name (e.g. `nvme0n1`). All commands below assume this name.
**Replace it with your actual disk name if different.**

---

## Phase 4: Create the Two NixOS Partitions

```bash
sudo cfdisk /dev/nvme0n1
```

In cfdisk:
1. Use arrow keys to highlight the **Free space** block.
2. Select **New** → set size to **`4G`** → press Enter.
   - Change its **Type** to **EFI System** (code `EF00`).
3. Highlight the remaining **Free space** again.
4. Select **New** → press Enter (use all remaining space).
   - Keep the type as **Linux filesystem**.
5. Select **Write** → type `yes` → **Quit**.

Run `lsblk` again to confirm your new partitions (e.g. `nvme0n1p5` for EFI, `nvme0n1p6` for Linux).

> **Replace `nvme0n1pX` with your EFI partition and `nvme0n1pY` with your Linux partition
> in every command from here on.**

---

## Phase 5: Format the EFI Partition

```bash
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1pX
```

---

## Phase 6: Set Up LUKS Encryption

```bash
# Create the LUKS2 container — you will be prompted to set a passphrase
sudo cryptsetup luksFormat --type luks2 \
  --allow-discards \
  --perf-no_read_workqueue \
  --perf-no_write_workqueue \
  /dev/nvme0n1pY

# Open the container — enter your passphrase
sudo cryptsetup open /dev/nvme0n1pY cryptroot
```

Your LUKS container is now available at `/dev/mapper/cryptroot`.

---

## Phase 7: Format BTRFS and Create Subvolumes

Create the following subvolume layout.

```bash
# Format BTRFS inside the LUKS container
sudo mkfs.btrfs -L nixos -f /dev/mapper/cryptroot

# Mount temporarily to create subvolumes
sudo mount /dev/mapper/cryptroot /mnt

# Create subvolumes
sudo btrfs subvolume create /mnt/root      # → mounted at /
sudo btrfs subvolume create /mnt/home      # → mounted at /home
sudo btrfs subvolume create /mnt/nix       # → mounted at /nix
sudo btrfs subvolume create /mnt/persist   # → mounted at /persist  (impermanence state)
sudo btrfs subvolume create /mnt/log       # → mounted at /var/log
sudo btrfs subvolume create /mnt/swap      # → holds the swapfile

sudo umount /mnt
```

---

## Phase 8: Mount Everything

```bash
# 1. Mount root subvolume
sudo mount -o compress=zstd,noatime,subvol=root /dev/mapper/cryptroot /mnt

# 2. Create mount points
sudo mkdir -p /mnt/{home,nix,persist,var/log,swap,boot}

# 3. Mount remaining subvolumes
sudo mount -o compress=zstd,noatime,subvol=home    /dev/mapper/cryptroot /mnt/home
sudo mount -o compress=zstd,noatime,subvol=nix     /dev/mapper/cryptroot /mnt/nix
sudo mount -o compress=zstd,noatime,subvol=persist /dev/mapper/cryptroot /mnt/persist
sudo mount -o compress=zstd,noatime,subvol=log     /dev/mapper/cryptroot /mnt/var/log

# Swap subvolume — no compression (incompatible with swap)
sudo mount -o noatime,subvol=swap /dev/mapper/cryptroot /mnt/swap

# 4. Create the swapfile (32G = matches your RAM, enables hibernation)
sudo btrfs filesystem mkswapfile --size 32G /mnt/swap/swapfile
sudo swapon /mnt/swap/swapfile

# 5. Mount the EFI partition
sudo mount /dev/nvme0n1pX /mnt/boot
```

Verify everything looks right:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
# You should see /mnt, /mnt/home, /mnt/nix, /mnt/persist, /mnt/var/log, /mnt/swap, /mnt/boot all mounted
```

---

## Phase 9: Generate Host SSH Key for Sops

The host's SSH ed25519 key is used by sops-nix to decrypt secrets at activation time.
Generate it **now** into the persistent partition so it survives reboots and is available
for the first `nixos-install`.

```bash
# 1. Create the SSH directory on the persistent partition
sudo mkdir -p /mnt/persist/etc/ssh

# 2. Generate the host key (empty passphrase)
sudo ssh-keygen -t ed25519 -f /mnt/persist/etc/ssh/ssh_host_ed25519_key -N ""
```

### Derive the age public key

sops-nix decrypts secrets using an age key derived from this SSH key. Derive it now:

```bash
nix-shell -p ssh-to-age --run \
  "ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub"
```

This prints an age public key like `age1abc...xyz`. **Copy this string** — you need it
in the next step.

### Add the key to `.sops.yaml`

On another machine (or in the same ISO session), edit `.sops.yaml` at the repo root:

1. Add the new host anchor under the `# Hosts` section:
   ```yaml
   - &my-computer age1abc...xyz
   ```

2. Add a `creation_rules` entry for the new host's secrets file:
   ```yaml
   - path_regex: hosts/my-computer/.*secrets-sops\.yaml$
     key_groups:
       - age:
           - *krit
           - *my-computer
   ```

3. Add the new host to the `krit-common-secrets-sops.yaml` rule so it can decrypt
   shared user secrets:
   ```yaml
   - path_regex: users/krit/common/sops/krit-common-secrets-sops.yaml$
     key_groups:
       - age:
           - *krit
           - *nixos-desktop
           - *Krits-MacBook-Pro
           - *my-computer          # ← add this
   ```

### Re-encrypt secrets for the new host

After updating `.sops.yaml`, re-encrypt so the new host key is added as a recipient:

```bash
# Re-encrypt common user secrets (the new host needs these)
sops updatekeys users/krit/common/sops/krit-common-secrets-sops.yaml
```

If you also created a host-specific secrets file (`hosts/my-computer/my-computer-secrets-sops.yaml`),
re-encrypt that too:

```bash
sops updatekeys hosts/my-computer/my-computer-secrets-sops.yaml
```

> **Tip:** If editing `.sops.yaml` on a separate machine, commit and push, then
> `git pull` on the ISO session before proceeding.

---

## Phase 10: Create Your Host

```bash
cd ~/nix/hosts
cp -r template-host-minimal my-computer
```

> **Note:** Do **not** copy or use the `disko-config-btrfs-luks-impermanence.nix` file.
> Disko would reformat the entire disk (including your Windows partition).
> The filesystems will be detected automatically by `nixos-generate-config` in Phase 12.

---

## Phase 11: Configure default.nix

Open `~/nix/hosts/my-computer/default.nix`.

### Set up imports (no disko)

In the `nixos` block, import only `hardware-configuration.nix` and sops.
Do **not** import any disko modules or configs:

```nix
nixos =
  { ... }:
  {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";
    imports = [
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix
    ];
  };
```

### Set your constants

Still in `default.nix`, update:

- **`user`**: your real username (not `template-user`)
- **`homeManagerSystem`**: `x86_64-linux` (Intel/AMD) or `aarch64-linux` (ARM)
- **`keyboardLayout`** / **`keyboardVariant`**: your keyboard (e.g. `"us"` / `""`)

---

## Phase 12: Generate Hardware Config and Install

```bash
# Generate hardware config — this auto-detects all mounted filesystems and LUKS
sudo nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ~/nix/hosts/my-computer/
```

### Add neededForBoot flags

Open the generated `hardware-configuration.nix` and add `neededForBoot = true` to
the `/persist` and `/var/log` entries (required for impermanence and early logging):

```bash
nano ~/nix/hosts/my-computer/hardware-configuration.nix
```

Find and update these two entries:

```nix
fileSystems."/persist" = {
  # ... existing options ...
  neededForBoot = true;  # ← add this line
};

fileSystems."/var/log" = {
  # ... existing options ...
  neededForBoot = true;  # ← add this line
};
```

> **Verify** the generated file contains entries for all six mount points
> (`/`, `/home`, `/nix`, `/persist`, `/var/log`, `/swap`), the boot partition (`/boot`),
> the LUKS device, and the swapfile.

### Install

```bash
# Stage all new files (CRITICAL: Nix flakes ignore untracked files)
cd ~/nix
git add hosts/my-computer/

# Install
sudo nixos-install --flake .#my-computer
```

---

## Phase 13: Finish

1. Set your **user password** when prompted.
   If not prompted:
   ```bash
   sudo nixos-enter
   passwd your-username
   exit
   ```

2. **CRITICAL** — copy your config to the persistent partition before rebooting:
   ```bash
   sudo cp -r ~/nix /mnt/persist/etc/nix
   ```

3. Reboot and remove the USB:
   ```bash
   reboot
   ```

---

## Phase 14: TPM Auto-Unlock (Post-Install)

After booting into your new system, bind the TPM so the drive unlocks automatically
at boot (no passphrase required).

```bash
# Enroll the TPM — enter your LUKS passphrase once when prompted
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1pY
```

**What this does:** The unlock key is sealed to your TPM, tied to firmware state
(PCR 0 = firmware, PCR 7 = Secure Boot policy). The drive auto-unlocks on every
normal boot. Your passphrase still works as a fallback at any time.

**Re-enroll after motherboard/firmware changes:**
```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1pY
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1pY
```

---

## Quick Reference: Partition Table After Installation

| Partition     | Device          | Size      | Type            | Content                      |
|---------------|-----------------|-----------|-----------------|------------------------------|
| Windows EFI   | nvme0n1p1       | ~100 MB   | EFI System      | Windows bootloader           |
| Windows MSR   | nvme0n1p2       | 16 MB     | Microsoft MSR   | —                            |
| Windows C:    | nvme0n1p3       | ~1,862 GiB| Microsoft Data  | NTFS                         |
| NixOS EFI     | nvme0n1pX       | 4 GiB     | EFI System      | vfat, /boot                  |
| NixOS LUKS    | nvme0n1pY       | ~1,858 GiB| Linux fs        | LUKS2 → BTRFS (cryptroot)    |

**BTRFS subvolumes inside cryptroot:**

| Subvolume | Mount Point | Options                        |
|-----------|-------------|--------------------------------|
| root      | /           | compress=zstd, noatime         |
| home      | /home       | compress=zstd, noatime         |
| nix       | /nix        | compress=zstd, noatime         |
| persist   | /persist    | compress=zstd, noatime         |
| log       | /var/log    | compress=zstd, noatime         |
| swap      | /swap       | noatime — 32G swapfile inside  |
