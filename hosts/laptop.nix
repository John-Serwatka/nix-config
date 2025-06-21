{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "laptop";
  # Use Intel or AMD driver, not NVIDIA!
  services.xserver.videoDrivers = [ "modesetting" ];

  # system.stateVersion is *required* for each host!
  system.stateVersion = "25.05";
}
