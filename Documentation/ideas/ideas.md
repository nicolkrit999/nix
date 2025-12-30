# Ideas
## General


### Improve screenshots keybinbings and default path to save
- Currently both keybindings and the path work in kde and hyprland. It would be nice to put them also in gnome and xfce to ensure consistency


## Theming/personalization
### Configure noctalia with quickshell
- Reference: https://docs.noctalia.dev/getting-started/nixos/


## DE/WM specific
### Cosmic desktop
- configure keybindings with a cosmic-binds.nix
- wait for the de to be more stable and declarative to setup custom system settings
- in the future it will probably be needed to tell stylix to not customize cosmic. For now this option does not exist

### Hyprland
- currently hyprland-main.nix hardcode ranger as variable for the file manager.
  - Ideally it should be smart and user the user chosen file manager
    - The issue is that there should be a separate logic based on whatever the chosen file manager is a gui or a cli  