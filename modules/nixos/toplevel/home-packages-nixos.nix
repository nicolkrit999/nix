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

      getPkg = name: pkgs.${name} or pkgs.kdePackages.${name} or null;

      programAliases = {
        "zen-beta" = [ "zen-browser" ];
      };

      userPackageNames = map lib.getName (
        lib.attrByPath [ "home-manager" "users" user "home" "packages" ] [ ] config
      );

      # nixpkgs-removed options (mkRemovedOptionModule) throw when read; treat them as not enabled
      readEnable =
        path:
        let
          r = builtins.tryEval (lib.attrByPath path false config);
        in
        r.success && r.value == true;

      isProgramEnabled =
        name:
        lib.any
          (n:
          readEnable [ "programs" n "enable" ]
          || readEnable [ "home-manager" "users" user "programs" n "enable" ])
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
        ++ [ pkgs.cliphist ];

      warnings = lib.concatLists (lib.mapAttrsToList
        (role: name:
          lib.optional (getPkg name == null && !isProvided name)
            "home-packages: constants ${role} = \"${name}\" is neither a package in pkgs/pkgs.kdePackages nor provided by an enabled module; nothing is installed for it.")
        roles);
    };
}
