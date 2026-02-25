# Things to fix

These are the issues that i observed that require attentions. They may be only on my machine but they also may be a general problem

- [Things to fix](#things-to-fix)
  - [Desktop environments specific](#desktop-environments-specific)
    - [Hyprland: gestures](#hyprland-gestures)
    - [Hyprland with caelestia/quickshell: fullscren recording with no audio does not work.](#hyprland-with-caelestiaquickshell-fullscren-recording-with-no-audio-does-not-work)
  - [General](#general)
    - [ profile: You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`. This will soon not be possible. Please remove all `nixpkgs` options when using \`home-manager](#-profile-you-have-set-either-nixpkgsconfig-or-nixpkgsoverlays-while-using-home-manageruseglobalpkgs-this-will-soon-not-be-possible-please-remove-all-nixpkgs-options-when-using-home-manager)
    - [programs.zsh.initExtra`is deprecated, use`programs.zsh.initContent\` instead.](#programszshinitextrais-deprecated-useprogramszshinitcontent-instead)
    - [Walker emojii keybind `waiting for elephant`](#walker-emojii-keybind-waiting-for-elephant)


## Desktop environments specific

### Hyprland: gestures

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

### Hyprland with caelestia/quickshell: fullscren recording with no audio does not work.

- It does not save it in the right folder
- This is a known problem and should be related to `gpu-screen-recorder`
- Activating a fullscreen recording with the terminal work

## General



