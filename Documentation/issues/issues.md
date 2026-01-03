# Things to fix
These are the issues that i observed that require attentions. They may be only on my machine but they also may be a general problem

- [Things to fix](#things-to-fix)
  - [Desktop environments specific](#desktop-environments-specific)
    - [Hyprland: gestures](#hyprland-gestures)
    - [Hyprland with caelestia: some fonts issue](#hyprland-with-caelestia-some-fonts-issue)
  - [General](#general)
    - ['system' has been renamed to/replaced by 'stdenv.hostPlatform.system'](#system-has-been-renamed-toreplaced-by-stdenvhostplatformsystem)
    - [ profile: You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`. This will soon not be possible. Please remove all `nixpkgs` options when using \`home-manager](#-profile-you-have-set-either-nixpkgsconfig-or-nixpkgsoverlays-while-using-home-manageruseglobalpkgs-this-will-soon-not-be-possible-please-remove-all-nixpkgs-options-when-using-home-manager)
    - [programs.zsh.initExtra`is deprecated, use`programs.zsh.initContent\` instead.](#programszshinitextrais-deprecated-useprogramszshinitcontent-instead)
  - [Guest user specific](#guest-user-specific)


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


### Hyprland with caelestia: some fonts issue
- Using certain fonts causes weird layout bugs, almost unusable
- I am unclear if this is an issue of caelestia or the nixcode that handle it
  - If something happen to the fonts the default one that works are the following:
    - Material font: Materials Symbols rounder
    - Monospace font: CaskaydiaCove NF
    - Sans-Serif font: Rubik

## General

###  'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
- N/A



###  <user> profile: You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`. This will soon not be possible. Please remove all `nixpkgs` options when using `home-manager
- According to a [reddit thread](https://www.reddit.com/r/NixOS/comments/1ivo70f/what_is_the_point_of_homemanageruseglobalpkgs_if/) it is stylix fault. Since the system build anyway for now this warning is harmless
  - For now we can ignore it 


### programs.zsh.initExtra` is deprecated, use `programs.zsh.initContent` instead.
- It should be a mismatch about what some inputs in home-manager expect and what other expects. Since the system build anyway for now this warning is harmless
  - For now we can ignore it 






## Guest user specific