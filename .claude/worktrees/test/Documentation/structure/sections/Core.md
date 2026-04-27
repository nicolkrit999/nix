- [❄️ Core Configuration](#️-core-configuration)
  - [🧠 Flake Entry Point](#-flake-entry-point)
- [`flake.nix`](#flakenix)
  - [🖥️ Hosts (`hosts/`)](#️-hosts-hosts)

# ❄️ Core Configuration

This section covers the entry point of the configuration, global variables, and host-specific definitions.

## 🧠 Flake Entry Point

# `flake.nix`

The brain of the operation. It defines the inputs and the enable `denix` automatic modules discovery


## 🖥️ Hosts (`hosts/`)

This directory contains the configurations for specific machines

Each hosts folder should contain at least this file otherwise the build would fail

- ### `default.nix`
- The machine-specific entry point. It configure denix constants, enable the chosen modules and other home-manager and/or system-related host-specific desired configurations such as disabling certain default folders and configure the users extra groups.
