{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;

      editorName =
        let
          e = myconfig.constants.editor;
        in
        if e == "nvim" then "neovim" else e;

      getPkg =
        name:
        if builtins.hasAttr name pkgs then
          pkgs.${name}
        else if builtins.hasAttr name pkgs.kdePackages then
          pkgs.kdePackages.${name}
        else
          null;

      programAliases = {
        "zen-beta" = [ "zen-browser" ];
      };

      userPackageNames = map lib.getName (
        lib.attrByPath [ "home-manager" "users" user "home" "packages" ] [ ] config
      );

      isProgramEnabled =
        name:
        lib.any
          (n:
          lib.attrByPath [ "programs" n "enable" ] false config
          || lib.attrByPath [ "home-manager" "users" user "programs" n "enable" ] false config)
          ([ name ] ++ (programAliases.${name} or [ ]));

      isProvided = name: isProgramEnabled name || builtins.elem name userPackageNames;

      roles = {
        terminal = myconfig.constants.terminal.name;
        browser = myconfig.constants.browser;
        fileManager = myconfig.constants.fileManager;
        editor = editorName;
      };
    in
    {
      environment.systemPackages =
        lib.concatMap
          (name:
            let
              pkg = getPkg name;
            in
            lib.optional (pkg != null && !isProgramEnabled name) pkg)
          (lib.attrValues roles)
        ++ [
          pkgs.cliphist
          pkgs.kdePackages.gwenview
        ];

      warnings = lib.concatLists (lib.mapAttrsToList
        (role: name:
          lib.optional (getPkg name == null && !isProvided name)
            "home-packages: constants ${role} = \"${name}\" is neither a package in pkgs/pkgs.kdePackages nor provided by an enabled module; nothing is installed for it.")
        roles);
    };
}
