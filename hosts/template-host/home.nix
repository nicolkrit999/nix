{ pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # 🏠 HOST-SPECIFIC HOME CONFIGURATION
  # ---------------------------------------------------------------------------
  # Use this file to install packages or modify settings ONLY for this specific machine.
  # This file is automatically imported if it exists.

  # EXAMPLE: Install specific tools
  # home.packages = with pkgs; [
  #   gimp
  #   blender
  # ];

  # EXAMPLE: Bind the installation of a file to a specific location
  # If the command "which" is run for that specific package it should return the path to the file.
  # home.file."tools/my-tool".source = pkgs.some-package;

  # EXAMPLE: Override XDG directories
  # folders specified as null will not be created
  # xdg.userDirs = {
  #   publicShare = null;
  #   templates = null;
  # };

  # home.sessionVariables = {
  #   JAVA_HOME = "${pkgs.jdk25}";
  #   JDTLS_BIN = "${pkgs.jdt-language-server}/bin/jdtls";
  #};

  # 5. other things
  # home.activation = {
  # createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  # mkdir -p
  # '';
  # };
}
