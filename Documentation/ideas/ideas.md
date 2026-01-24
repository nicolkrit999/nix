# Ideas
## General

### Add virtual keyboard support to sddm
- I tried both with x11, wayland, maliit, qvirtualkeyboard, root access to sddm user and groups "inputs" and "wheels" but nothing worked



## DE/WM specific
### General


### Cosmic desktop
- configure keybindings with a cosmic-binds.nix
- wait for the de to be more stable and declarative to setup custom system settings
- in the future it will probably be needed to tell stylix to not customize cosmic. For now this option does not exist

### Hyprland
- N/A

## guest user
### Change logic from reboot to kickout when accessing a non xfce session
- I would like the guest user to be kicked out when it tries to load a non xfce session.
  - I tried with single scripts that kick out on every de-related files inside /nixos/modules. It worked but that add to much complexity and everytime a de/wm is added then a new kickout must be created
  - I tried with single sddm script that recognize a session that is not ssdm. I made some progress but it would either ignore it (meaning the user can still do anything) or just crash the pc and require a reboot as soon as the guest user log out
- Ideally it should be a single thing in guest.nix which recognize unwanted sessions and act accordingly
