{ denix, moduleSystem }:
denix.lib.extension {
  name = "home-user-follows-constants";
  libExtension = _config: _final: prev:
    let
      args = prev._callLibArgs;
      orig = args.apply;
      home = _home:
        if moduleSystem == "home" || !args.useHomeManagerModule then
          orig.home _home
        else
          { config, ... }: { home-manager.users.${config.${args.myconfigName}.constants.user} = _home; };
    in
    {
      _callLibArgs = args // {
        apply = orig // {
          inherit home;
          listOfEverything = _myconfig: _nixos: _home: _darwin: [
            (orig.myconfig _myconfig)
            (orig.nixos _nixos)
            (home _home)
            (orig.darwin _darwin)
          ];
        };
      };
    };
}
