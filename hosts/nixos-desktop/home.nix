{ pkgs, lib, ... }:

{
  # ☕ JAVA TOOLS
  # This only exists on this specific machine
  home.file."tools/jdtls".source = pkgs.jdt-language-server;

  # 📂 XDG OVERRIDES
  # Disable folders I don't use
  xdg.userDirs = {
    publicShare = null;
    music = null;
  };

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk25}";
    JDTLS_BIN = "${pkgs.jdt-language-server}/bin/jdtls";
  };

  # 5. Create/remove host-specific directories
  home.activation = {
    createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/Pictures/wallpapers
    '';
  };
}
