{ delib
, pkgs
, ...
}:
let
  sharedPackages = with pkgs; [
    asciinema # Record and share terminal sessions
    neo-cowsay # Cowsay reborn (ASCII art with text)
    pay-respects
    vscode # Microsoft visual studio code IDE
  ];
in
delib.module {
  name = "krit.services.local-packages-common";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      # Ventoy: precompiled blobs, insecure pin (nixpkgs#404663); update on bump, drop when knownVulnerabilities clears
      nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.18" ];

      users.users.${myconfig.constants.user}.packages = sharedPackages ++ (with pkgs; [
        # Desktop applications
        censor # PDF document redaction for the GNOME desktop
        czkawka # Find duplicates, empty folders, similar images etc.
        drawio # Diagramming application
        gearlever # Manager for AppImages
        google-chrome # Freeware web browser developed by Google
        gramps # Genealogy software
        jellyfin-desktop # Jellyfin media player client
        libreoffice-qt # Open source microsoft office alternative
        lufus # A rufus clone written in py and designed to work with linux
        obs-studio # Streaming/Recording
        proton-pass # Password manager by Proton
        proton-pass-cli # Command-line interface for managing your Proton Pass vaults, items, and secrets
        saber # Cross-platform open-source app built for handwriting
        shortwave # Find and listen to internet radio stations
        teams-for-linux # Unofficial Microsoft Teams client
        tor-browser # Privacy-focused web browser
        ventoy-full-qt # New Bootable USB Solution with GUI support

        # CLI utilities
        gallery-dl # Command-line program to download image-galleries and -collections from several image hosting sites
        tealdeer # Fast implementation of tldr (simplified man pages)

        # Coding
        zeal # Offline documentation browser

        # Fun
        pipes # Terminal pipes animation
      ]);
    };

  darwin.ifEnabled =
    _:
    {
      environment.systemPackages = sharedPackages;
    };
}
