- [❄️ Core Configuration](#️-core-configuration)
  - [🧠 Flake Entry Point](#-flake-entry-point)
- [`flake.nix`](#flakenix)
  - [🖥️ Hosts (`hosts/`)](#️-hosts-hosts)

# ❄️ Core Configuration

This section covers the entry point of the configuration, global variables, and host-specific definitions.

## 🧠 Flake Entry Point

# `flake.nix`

The brain of the operation. It defines the inputs (Nixpkgs source, Home Manager version, Catppuccin theme if applicable) and the `nixosConfigurations` for your machine. It ties the System modules and Home Manager modules together.

- **Fetch global Variables:** Take the host-specific variables and apply them to create the personalized system.
- **Unfree Packages:** Globally allows unfree packages for both the system and Home Manager, removing the need to enable them in individual files.
- **Formatter:** Defines `nixfmt-rfc-style` as the default formatter for `nix fmt`.

## 🖥️ Hosts (`hosts/`)

This directory contains the configurations for specific machines. Each folder name need to match the name of a `hostname` defined in `flake.nix`.

Each hosts folder should contain at least these 3 files otherwise the build would fail

- ### `configuration.nix`
- The machine-specific entry point. It imports the hardware scan and any host-specific module overrides.

- ### `hardware-configuration.nix`
- An auto-generated file which contains optimization based on the hardware of that specific machine.
- This file should not be changed unless the user is confident

- ### `variables.nix`
- It is the place where the user change all the aspects that may be host-specific. For example the theming, the username and similar
