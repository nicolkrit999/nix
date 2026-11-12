{ lib }:
let
  nonEmpty = text: lib.filter (l: lib.trim l != "") (lib.splitString "\n" text);
  sortedChord = sep: s: lib.concatStringsSep "+" (lib.sort (a: b: a < b) (map (x: lib.toLower (lib.trim x)) (lib.splitString sep s)));
  dups = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);

  luaCalls = text:
    lib.concatMap
      (l:
        let m = builtins.match ''hl\.(unbind|bind)\("([^"]*)".*'' (lib.trim l); in
        lib.optional (m != null) { kind = builtins.elemAt m 0; chord = sortedChord " + " (builtins.elemAt m 1); })
      (nonEmpty text);

  niriChords = text:
    lib.concatMap
      (l:
        let m = builtins.match "    ([^ ]+) .*[{].*[}].*" l; in
        lib.optional (m != null) (sortedChord "+" (builtins.head m)))
      (nonEmpty text);

  luaPairingOk = text:
    let c = luaCalls text; in
    c != [ ] && lib.length c == 2 * (lib.length c / 2)
    && lib.all (i: (builtins.elemAt c (2 * i)).kind == "unbind" && (builtins.elemAt c (2 * i + 1)).kind == "bind" && (builtins.elemAt c (2 * i)).chord == (builtins.elemAt c (2 * i + 1)).chord)
      (lib.range 0 (lib.length c / 2 - 1));
  luaBindChords = text: map (c: c.chord) (lib.filter (c: c.kind == "bind") (luaCalls text));

  legacyWords = [ "vicinae" "swayosd" "swaync" "waybar" "grimblast" ];
  legacyHits = text: lib.filter (w: lib.hasInfix w text) legacyWords;

  bareTools = [ "install" "rm" "cp" "chown" "chmod" "mkdir" "ln" "mv" "cat" "sed" "mktemp" "jq" "flock" ];
  bareToolLines = text: lib.filter (l: let t = lib.trim l; in lib.any (w: lib.hasPrefix "${w} " t) bareTools) (lib.splitString "\n" text);
  sentinelAfterSave = text:
    let
      parts = lib.splitString "fastfetch save" text;
      w = ": > \"$sentinel\"";
    in
    lib.length parts == 2 && !(lib.hasInfix w (builtins.elemAt parts 0)) && lib.hasInfix w (builtins.elemAt parts 1);

  repoSyncUnits = {
    ryoku-dotfiles-sync = { url = "https://github.com/nicolkrit999/dotfiles"; ssh = false; };
    ryoku-nix-sync = { url = "https://github.com/nicolkrit999/nix"; ssh = false; };
    ryoku-dotfiles-private-sync = { url = "ssh://git@gitea-ssh.nicolkrit.ch:2222/krit/dotfiles-private.git"; ssh = true; };
  };
  repoSyncCommon = [
    "merge --quiet --ff-only"
    "status --porcelain"
    "rev-list --count"
    "--unshallow"
    "remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'"
    "GIT_TERMINAL_PROMPT=0"
    "mktemp -d"
    "rm -rf \"$tmp\""
  ];
  repoSyncSsh = [ "id_github" "IdentitiesOnly=yes" "StrictHostKeyChecking=yes" "UserKnownHostsFile=" "ryoku-gitea-known-hosts" "gitea-ssh.nicolkrit.ch" ];
  repoSyncForbidden = [
    "reset"
    "--hard"
    "--depth"
    "--branch"
    "clean -"
    "-C \"$dir\" checkout"
    "rm -rf \"$dir\""
    "PRIVATE KEY"
    "AAAAC3"
    "ghp_"
    "github_pat_"
  ];
  repoSyncPublicForbidden = [ "id_github" "GIT_SSH_COMMAND" "git@" "ssh://" "gitea" ];
  repoSyncProblems = { url, ssh }: text:
    let
      required = repoSyncCommon ++ [ url ] ++ lib.optionals ssh repoSyncSsh;
      forbidden = repoSyncForbidden ++ lib.optionals (!ssh) repoSyncPublicForbidden ++ lib.optional ssh "github.com";
    in
    map (n: "missing: ${n}") (lib.filter (n: !(lib.hasInfix n text)) required)
    ++ map (n: "forbidden: ${n}") (lib.filter (n: lib.hasInfix n text) forbidden);
in
{
  inherit repoSyncUnits repoSyncProblems sentinelAfterSave dups luaCalls luaBindChords luaPairingOk niriChords legacyHits bareToolLines;
}
