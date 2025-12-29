# Things to fix
These are the issues that i observed that require attentions. They may be only on my machine but they also may be a general problem

- [Things to fix](#things-to-fix)
  - [Desktop environments specific](#desktop-environments-specific)
    - [Chromium doesn't open on kde x11](#chromium-doesnt-open-on-kde-x11)
    - [Hyprland gestures](#hyprland-gestures)
  - [General](#general)
    - [During rebuild: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'](#during-rebuild-system-has-been-renamed-toreplaced-by-stdenvhostplatformsystem)
  - [Guest user specific](#guest-user-specific)
    - [User remains active in tty\*](#user-remains-active-in-tty)


## Desktop environments specific
### Chromium doesn't open on kde x11
- on kde wayland it is not a problem
- Possible ideas: N/A 

### Hyprland gestures
- related file `home-manager/modules/hyprland/main.ni
  - I tried with the following code but didn´t work 
- see https://wiki.hypr.land/Configuring/Gestures/

```nix
 gestures = {
          workspace_swipe = true;
          workspace_swipe_invert = false;
          workspace_swipe_forever = true;
        };

        gesture = [
          "3, horizontal, workspace"
        ];
```

## General
### During rebuild: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
- I tried but didn't found a proper way to handle it
- Modifying `flake.nix` should be enough




## Guest user specific
### User remains active in tty*
- When the guest log in a session where it is not allowed and the kickout script run then if the main user tries to reboot via cli it is greeted with a warning
- The guest user is still logged in tty*, there are as many tty as many times the script runned, 1 per desktop environment
  - This means if the user did 2 wrong login (hyprland + kde wayland) for example it would still be logged in tty1 and tty2
- The main user is then prompted to run systemctl reboot -i
  - This solve the problem and the pc actually boot, but it should be ideally logged out completely 
- The guest kickout script are handled in `guest.nix`, `hyprland.nix` and `kde.nix`