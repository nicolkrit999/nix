# optional/dev-environments/default.nix
{ lib, ... }:

let
  vars = import ../../variables.nix;

  langs = vars.devLanguages; # e.g., ["java" "rust"]

  validImports = map (lang: ./. + "/${lang}") langs;
in
{
  imports = validImports;
}
