{
  pkgs,
  pkgs-unstable,
  user,
  ...
}:
{
  users.users.${user}.packages =
    with pkgs;
    [
    ]

    ++ (with pkgs-unstable; [
    ]);
}
