{
  pkgs,
  lib,
  vars,
  ...
}:
let
  browserPkg = pkgs.${vars.browser};
  browserBin = "${browserPkg}/bin/${vars.browser}";

  isFirefox = vars.browser == "firefox" || vars.browser == "librewolf" || vars.browser == "floorp";

  mkWebApp = name: url: icon: {
    inherit name icon;
    genericName = "Web Application";
    # Logic: If Firefox, use --new-window. If Chromium-based, use --app=URL for true "App Mode".
    exec = if isFirefox then "${browserBin} --new-window ${url}" else "${browserBin} --app=${url}";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    type = "Application";
  };
in
{
  xdg.desktopEntries = {
    dashboard = mkWebApp "Dashboard - Glance" "https://glance.nicolkrit.ch/" "utilities-system-monitor";

    nas = mkWebApp "NAS" "https://nas.nicolkrit.ch" "network-server";

    linkwarden = mkWebApp "Linkwarden" "https://linkwarden.nicolkrit.ch/dashboard" "emblem-favorite";

    nix-search = mkWebApp "Nix Search" "https://search.nixos.org/packages" "system-search";

    proton-mail = mkWebApp "Proton Mail" "https://mail.proton.me/u" "internet-mail";

    owncloud = mkWebApp "OwnCloud" "https://owncloud.nicolkrit.ch/" "folder-cloud";

    google-gemini = mkWebApp "Google Gemini AI" "https://gemini.google.com/app" "utilities-terminal";

    github = mkWebApp "Github" "https://github.com/" "vcs-git";

    proton-drive = mkWebApp "Proton Drive" "https://drive.proton.me/u/0/" "drive-harddisk";

    reddit = mkWebApp "Reddit" "https://www.reddit.com/" "internet-news-reader";
  };
}
