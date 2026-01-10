
# 🔐 Secret Management (SOPS + Nix)

This repository uses **SOPS** (Secrets OPerationS) to manage sensitive data (passwords, tokens, keys). Files are **encrypted at rest** (safe for GitHub) and **decrypted at runtime** by the specific host or user that needs them.

## 1. How It Works

### The Keys

We use two types of keys:

1. **User Key (Age):** A private key on your personal computer (`~/.config/sops/age/keys.txt`). This allows **YOU** to edit/view any secret in the repo.
2. **Host Keys (SSH):** The standard SSH private key (`/etc/ssh/ssh_host_ed25519_key`) generated when a Linux machine is installed. This allows the **MACHINE** (Desktop, Laptop) to decrypt secrets at boot time.

### The Flow

1. **Encryption:** When you save a file, `sops` looks at the **Public Keys** (`/etc/ssh/ssh_host_ed25519_key.pub`) listed in the file header and encrypts the content for them.
2. **Matching:** `sops` decides *which* public keys to use based on the **file path**.
3. **Decryption:** At boot, NixOS uses the host's private SSH key to decrypt the file into RAM (`/run/secrets/`). The unencrypted secret never touches the disk.
   - The secrets path contains all the secrets that are related to that host 

---

## 2. How Matching Works (The Traffic Controller)

`sops` does not know what a "Desktop" or "Laptop" is. It simply uses **Regex** to match file paths to keys in `.sops.yaml`.

| If file path matches... | Then encrypt for...                    |
| ----------------------- | -------------------------------------- |
| `hosts/desktop/.*`      | User (Krit) + Desktop Host Key         |
| `hosts/laptop/.*`       | User (Krit) + Laptop Host Key          |
| `common/.*`             | User (Krit) + Desktop Key + Laptop Key |

*If you put a file in the wrong folder, it gets encrypted with the wrong keys.*

### What happens if it gets encrypted with the wrong key?

If you accidentally save a file in `hosts/desktop/` that was meant for the `hosts/laptop`:

1. **The Consequence:** The Laptop will fail to deploy or boot correctly. When it tries to read the secret, it will get a **"Decryption failed"** or **"No matching key found"** error because the file was locked using the Desktop's public key, not the Laptop's.
2. **Is it reversible?** **YES.**
* Since your **User Key** is included in *every* rule in `.sops.yaml` (standard practice), **YOU** can still open the file.
* You simply move the file to the correct folder and tell `sops` to update the keys.



#### Troubleshooting: Wrong Keys / Wrong Folder

**Problem:** You created a secret file in the wrong folder (e.g., you put laptop secrets in the desktop folder), or you moved a file and now the host cannot read it.

**Why:** The file header contains the list of allowed keys. If you move a file, the header does *not* automatically update. The file is still encrypted for the old keys (Desktop), so the new host (Laptop) cannot open it.

**The Fix:**

1. **Move** the file to the correct directory.
2. **Update** the encryption keys to match the new folder's rules.

```bash
# 1. Move the file
mv hosts/desktop/secrets.yaml hosts/laptop/secrets.yaml

# 2. Re-encrypt it with the correct keys (Laptop + User)
sops updatekeys hosts/laptop/secrets.yaml
```

*Note: As long as your personal User Key is in the file's access list, you can always recover and fix this.*

---

## 3. How to Manage Secrets

### A. Edit a Host-Specific Secret

1. Navigate to the correct folder (e.g., `hosts/desktop`).
2. Run the command:
```bash
sops secrets.yaml
```


3. The file opens in your editor (decrypted). Make changes and save.
4. `sops` automatically re-encrypts it on exit.
5. Commit and push.

### B. Create/Edit a Common Secret

Common secrets (like WiFi passwords) must be readable by **all** machines. that share a certain key

1. **Update `.sops.yaml`:** Ensure there is a rule for the `common/` folder that lists **all** host keys.
```yaml
- path_regex: common/secrets.yaml$
  key_groups:
    - age: [ *user_krit, *pc_desktop, *pc_laptop ]

```


2. **Create/Edit the file:**
```bash
sops common/secrets.yaml
```


*Note: If you add a NEW host later, you must re-open and save this file so the new host's key is added to the encryption header.*
3. **Use in Nix:** In your `configuration.nix`, point to this specific file:
```nix
sops.secrets.wifi_password.sopsFile = ../../common/secrets.yaml;
```
Here is the README section. I have written it as a "Security FAQ" because this is a very common question that is important to clarify for anyone reading your repo.

---

#### 4. Security FAQ: Usernames & Common Secrets

**Q: If I have a `common/secrets.yaml` shared by all my machines, can a stranger read it if they clone my repo and name their user `<username>` (same as mine)?**

**A: NO.**

### Why is this safe?

In cryptography, **Usernames are irrelevant.** They are just text labels. `sops` and `age` do not check your username; they check your **Private Key**.

1. **Machine Identity != User Name:**
When you encrypt a file for "The Desktop", you are encrypting it for that specific machine's unique SSH Private Key (`/etc/ssh/ssh_host_ed25519_key`).
2. **The Stranger's Scenario:**
If a stranger clones your repo and creates a user named `krit`:
* They have the same *name* tag.
* But they do **not** have your computer's physical **Private Key**.
* Therefore, when their machine tries to decrypt `common/secrets.yaml`, it fails immediately. The file looks like random garbage to them.


3. **Access Control:**
You cannot simply "join" the common secrets club. A new machine can only read `common/secrets.yaml` if **YOU** (the owner) manually re-encrypt that file to explicitly include the new machine's public key in the header.

**Summary:** Your security relies on keeping your **Private Keys** (`keys.txt` and `ssh_host_ed25519_key`) safe. As long as those are not shared, your public repository is secure, regardless of what usernames people use.


---

## 4. Setup Guide: New Personal PC

If you buy a new computer and want to use this repo:

### Scenario A: Clean Start (New Identity)

1. Install NixOS. It generates a **new** unique SSH host key.
2. Get the new public key (print it with `cat /etc/ssh/ssh_host_ed25519_key.pub`).
3. On your old PC (or current working environment), add this new key to `.sops.yaml`.
4. Run `sops updatekeys hosts/new-pc/secrets.yaml` to re-encrypt the file for the new machine.

### Scenario B: Restore Identity (Recommended)

1. Install NixOS.
2. **Before** rebuilding from this flake, overwrite the auto-generated SSH keys in `/etc/ssh/` with the **backup keys** you stored (hopefully) in another secure location.
3. Now the new machine "is" the old machine. It can decrypt everything immediately without changing `.sops.yaml`.

---

## 5. External Users (Forks & Copies)

If someone else (a stranger) forks or downloads this repository:

| Action         | Can they read your secrets?                                                                                  | What must they do?                                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Fork/Clone** | **NO.** They do not have your private Age key or your Host SSH key. The files are just garbage text to them. | They must delete your `secrets.yaml` files.                                                                                                     |
| **Setup**      | **N/A**                                                                                                      | They must generate their own Age key, add their own Host keys to `.sops.yaml`, and run `sops secrets.yaml` to create their own encrypted files. |
