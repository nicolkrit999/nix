{
  inputs,
  pkgs,
  lib,
  vars,
  ...
}:
{

  # -----------------------------------------------------------------------
  # 🔗 IMPORTS
  # -----------------------------------------------------------------------
  # Pulls in all individual program modules (Hyprland, Zsh, Neovim, etc.)
  imports = [
    ./modules/core.nix
    ./home-packages.nix
  ];

  # -----------------------------------------------------------------------
  # 👤 USER IDENTITY
  # -----------------------------------------------------------------------
  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = vars.homeStateVersion; # Controls backwards compatibility logic
  };

  # -----------------------------------------------------------------------
  # 🏠 HOME MANAGER SELF-MANAGEMENT
  # -----------------------------------------------------------------------
  programs.home-manager.enable = true;

  xdg = {
    enable = true;

    # Ensures mime.nix settings are actually applied
    mimeApps.enable = true;

    # Create default user directories
    # Specific directories can be disabled in the host-specific home.nix file
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Create applications.menu for kde
  # This allow kde applications such as dolphin to pick up the default applications to use for mime types
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
    "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include>
        <Category>System</Category>
        <Category>Utility</Category>
      </Include>
    </Menu>
  '';

  # -----------------------------------------------------------------------
  # 🛠️ ACTIVATION SCRIPTS
  # -----------------------------------------------------------------------
  # DESCRIPTION:
  # Scripts that run during the 'switch' process to perform tasks that
  # declarative Nix cannot do alone (like creating deep subdirectories).
  # -----------------------------------------------------------------------

  home.activation = {

    # ⚠️ Do not add ~/.config/hypr/hyprland.conf otherwise during rebuild the config change and you need to manually reapply home-manager and then logging out/in to see the changes.
    # The file need to be removed manually if needed before rebuilding
    removeExistingConfigs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "/home/${vars.user}/.gtkrc-2.0"
      rm -f "/home/${vars.user}/.config/gtk-3.0/settings.ini"
      rm -f "/home/${vars.user}/.config/gtk-3.0/gtk.css"
      rm -f "/home/${vars.user}/.config/gtk-4.0/settings.ini"
      rm -f "/home/${vars.user}/.config/gtk-4.0/gtk.css"
      rm -f "/home/${vars.user}/.config/dolphinrc"
      rm -f "/home/${vars.user}/.local/share/applications/mimeapps.list"
    '';

    createEssentialDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Screenshots directory (references in other files. Make sure to change accordingly)
      mkdir -p ${vars.screenshots}
    '';
  };
}
