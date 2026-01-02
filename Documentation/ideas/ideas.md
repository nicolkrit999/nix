# Ideas
## General


### Improve screenshots keybinbings and default path to save
- Currently both keybindings and the path work in kde and hyprland. It would be nice to put them also in gnome and xfce to ensure consistency


## Theming/personalization
### Configure noctalia with quickshell
- Reference: https://docs.noctalia.dev/getting-started/nixos/


## DE/WM specific
### General
- Configure the keybindings to be declarative in regard of the file manager, the terminal and the file editor according to the host-specific variables


### Cosmic desktop
- configure keybindings with a cosmic-binds.nix
- wait for the de to be more stable and declarative to setup custom system settings
- in the future it will probably be needed to tell stylix to not customize cosmic. For now this option does not exist

### Hyprland
- currently hyprland-main.nix hardcode ranger as variable for the file manager.
  - Ideally it should be smart and user the user chosen file manager
    - The issue is that there should be a separate logic based on whatever the chosen file manager is a gui or a cli 

## guest user
### Change logic from reboot to kickout when accessing a non xfce session
- I would like the guest user to be kicked out when it tries to load a non xfce session.
  - I tried with single scripts that kick out on every de-related files inside /nixos/modules. It worked but that add to much complexity and everytime a de/wm is added then a new kickout must be created
  - I tried with single sddm script that recognize a session that is not ssdm. I made some progress but it would either ignore it (meaning the user can still do anything) or just crash the pc and require a reboot as soon as the guest user log out
- Ideally it should be a single thing in guest.nix which recognize unwanted sessions and act accordingly  