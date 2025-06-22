# home/desktop.nix
{ config, pkgs, ... }:

{
  imports = [ ./home.nix ];       # pick up username, shells, etc.

  # Set *exactly* one* home.packages* here:
  home.packages = (import ./shared-packages.nix { inherit pkgs; })
               ++ (with pkgs; [
                    ckb-next
                    piper
                    libratbag
                 ]);

  # Any other desktop‐only HM config goes here…
}
