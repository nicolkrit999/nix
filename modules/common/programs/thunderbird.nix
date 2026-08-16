{ delib, lib, config, pkgs, ... }:
let
  mkSopsSecrets = { myconfig, user }:
    let
      names = lib.unique (lib.flatten (map
        (a: [ a.addressLocalSecretName a.addressDomainSecretName ]
          ++ lib.optional (a.passwordSecretName != null) a.passwordSecretName)
        myconfig.programs.thunderbird.accounts));
    in
    lib.genAttrs names (_: {
      sopsFile = myconfig.programs.thunderbird.sopsFile;
      owner = user;
    });
in
delib.module {
  name = "programs.thunderbird";

  options = delib.moduleOptions {
    enable = delib.boolOption false;

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Sops-encrypted yaml file holding this host's account secrets.";
    };

    accounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Internal account id, used as the accounts.email.accounts.<name> key.";
          };
          addressLocalSecretName = lib.mkOption {
            type = lib.types.str;
            description = "sops secret name holding the address's local part (before the @).";
          };
          addressDomainSecretName = lib.mkOption {
            type = lib.types.str;
            description = "sops secret name holding the address's domain (after the @).";
          };
          realName = lib.mkOption {
            type = lib.types.str;
            description = "Display name for this account.";
          };
          flavor = lib.mkOption {
            type = lib.types.str;
            default = "plain";
            description = "Passed straight through to accounts.email.accounts.<name>.flavor.";
          };
          primary = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this is the primary email account.";
          };
          authentication = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IMAP/SMTP authentication method; leave null for OAuth2 auto-negotiation.";
          };
          passwordSecretName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "sops secret name holding this account's password; leave null for OAuth2.";
          };
        };
      });
      default = [ ];
      description = "Thunderbird email accounts to configure declaratively.";
    };
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = mkSopsSecrets { inherit myconfig user; };

      sops.templates."tb-user-js" = {
        file = config.home-manager.users.${user}.home.file.".thunderbird/default/user.js".source;
        path = "/home/${user}/.thunderbird/default/user.js";
        owner = user;
        mode = "0400";
      };

      system.activationScripts.thunderbirdProfileDirs = {
        deps = [ "users" "groups" ];
        text = ''
          install -d -o ${user} -g ${config.users.users.${user}.group} -m 0700 \
            /home/${user}/.thunderbird \
            /home/${user}/.thunderbird/default
        '';
      };
    };

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = mkSopsSecrets { inherit myconfig user; };

      sops.templates."tb-user-js" = {
        file = config.home-manager.users.${user}.home.file."Library/Thunderbird/Profiles/default/user.js".source;
        path = "/Users/${user}/Library/Thunderbird/Profiles/default/user.js";
        owner = user;
        mode = "0400";
      };

      system.activationScripts.preActivation.text = ''
        mkdir -p /Users/${user}/Library/Thunderbird/Profiles/default
        chown ${user}:staff \
          /Users/${user}/Library/Thunderbird \
          /Users/${user}/Library/Thunderbird/Profiles \
          /Users/${user}/Library/Thunderbird/Profiles/default
        chmod 0700 \
          /Users/${user}/Library/Thunderbird \
          /Users/${user}/Library/Thunderbird/Profiles \
          /Users/${user}/Library/Thunderbird/Profiles/default
      '';
    };

  home.ifEnabled =
    { myconfig, ... }:
    let
      userJsKey =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "Library/Thunderbird/Profiles/default/user.js"
        else ".thunderbird/default/user.js";
    in
    {
      home.file.${userJsKey}.enable = false;

      programs.thunderbird = {
        enable = true;
        profiles.default.isDefault = true;
      };

      accounts.email.accounts = lib.listToAttrs (map
        (a: {
          name = a.name;
          value = lib.mkMerge [
            {
              address = "${config.sops.placeholder.${a.addressLocalSecretName}}@${config.sops.placeholder.${a.addressDomainSecretName}}";
              realName = a.realName;
              flavor = a.flavor;
              primary = a.primary;
              thunderbird.enable = true;
            }
            (lib.optionalAttrs (a.authentication != null) {
              imap.authentication = a.authentication;
              smtp.authentication = a.authentication;
            })
            (lib.optionalAttrs (a.passwordSecretName != null) {
              passwordCommand = [ "cat" "/run/secrets/${a.passwordSecretName}" ];
            })
          ];
        })
        myconfig.programs.thunderbird.accounts);
    };
}
