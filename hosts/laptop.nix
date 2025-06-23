# hosts/laptop.nix — laptop-specific system config
{ config, pkgs, ... }:

{
  imports = [
    ../modules/shared.nix
    ../modules/apps/base.nix
    ../modules/apps/games.nix
    ../modules/services/flatpak.nix
    ../modules/services/steam.nix
    ../modules/services/syncthing.nix
    ../modules/hardware/intel-gpu.nix
  ];

  system.stateVersion = "25.05";

  networking.hostName = "laptop";
  # add laptop-only options (touchpad, battery, etc.) here
}
