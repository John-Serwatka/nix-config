# modules/services/steam.nix
{ config, lib, pkgs, ... }:
{
  programs.steam = {
    enable                 = true;
    remotePlay.openFirewall      = true;  # if you use Steam Remote Play
    localNetworkGameTransfers.openFirewall = true;
    # dedicatedServer.openFirewall = true;  # if you run source servers
  };

  # And make sure unfree is allowed for steam & steam-run:
  nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [
    "steam" "steam-unwrapped" "steam-run"
  ];
}
