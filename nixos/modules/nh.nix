{ vars, ... }:
{
  programs.nh = {
    enable = true;

    # -----------------------------------------------------------------------
    # ❄️ PROGRAM: NH (Nix Helper)
    # -----------------------------------------------------------------------
    # DESCRIPTION:
    # A cleaner, more user-friendly interface for Nix commands. It handles
    # system updates (sw) and user updates (hms) with better progress bars
    # and automatic cleanup of old system generations.
    # -----------------------------------------------------------------------

    # Optional: Periodic automatic garbage collection after updates
    # clean.enable = true;
    # clean.extraArgs = "--keep-since 4d --keep 3";

    # Location of your flake configuration for quick discovery by nh commands
    flake = "/home/${vars.user}/nixOS";
  };
}
