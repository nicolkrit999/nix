# YubiKey (FIDO2 via pam_u2f) as a `sufficient` alternative to the password,
# always PIN + touch (pinverification=1, userpresence=1), never touch alone.
# Key login does not unlock the keyring (pam_unix is skipped, PAM_AUTHTOK is
# unset), so expect one keyring password prompt per session.
# The authfile is a root-owned sops template in /run, not user-writable.
# Enroll: pamu2fcfg -N -n -o pam://yubi | sed 's/^://'
# and store the output as the sops secret named in keySecrets.
{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "services.yubikey-auth";

  options = with delib; moduleOptions {
    enable = boolOption false;
    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "sops file holding the keySecrets; null means the host's sops.defaultSopsFile.";
    };
    keySecrets = listOfOption str [ ];
    user = strOption "";
    origin = strOption "pam://yubi";
    services = listOfOption str [ "login" "sudo" "polkit-1" "hyprlock" "kde" "cosmic-greeter" ];
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      anyWm = (myconfig.programs.hyprland.enable or false) || (myconfig.programs.niri.enable or false) || (myconfig.programs.mango.enable or false);
      # A name is only used when a module really defines that PAM service on this host (or specialisation); naming any other would create a stray /etc/pam.d file.
      # Every installed desktop's lock service is listed, so switching desktop in the same boot needs nothing: PAM is read per service, not per session.
      defined = {
        login = true; # repo common-configuration-nixos
        sudo = config.security.sudo.enable;
        polkit-1 = config.security.polkit.enable;
        hyprlock = anyWm; # repo services.hyprlock, same gate
        kde = config.services.desktopManager.plasma6.enable; # kscreenlocker
        cosmic-greeter = config.services.desktopManager.cosmic.enable; # COSMIC lock and greeter share it
      };
      services = lib.filter (s: defined.${s} or false) cfg.services;
      user = if cfg.user != "" then cfg.user else config.myconfig.constants.user;
      sopsFile = if cfg.sopsFile != null then cfg.sopsFile else config.sops.defaultSopsFile;
      sopsText = builtins.readFile sopsFile;
      present = lib.filter (n: lib.hasInfix "${n}:" sopsText) cfg.keySecrets;
      missing = lib.subtractLists present cfg.keySecrets;
      active = present != [ ];
    in
    {
      warnings = lib.optional (missing != [ ])
        "services.yubikey-auth: sops secrets not found in ${toString sopsFile}: ${lib.concatStringsSep ", " missing}${lib.optionalString (!active) " (u2f stays disabled)"}";

      environment.systemPackages = [ pkgs.pam_u2f pkgs.yubikey-manager ];

      services.udev.packages = [ pkgs.libfido2 ];

      sops.secrets = lib.genAttrs present (_: { inherit sopsFile; });

      sops.templates."u2f-keys" = lib.mkIf active {
        content = "${user}:" + lib.concatStringsSep ":" (map (n: config.sops.placeholder.${n}) present);
        owner = "root";
        mode = "0444";
      };

      security.pam.u2f.settings = lib.mkIf active {
        origin = cfg.origin;
        authfile = config.sops.templates."u2f-keys".path;
        pinverification = 1;
        userpresence = 1;
        userverification = 0;
        cue = true;
      };

      security.pam.services = lib.mkIf active (lib.genAttrs services (_: { u2f.enable = true; }));
    };
}
