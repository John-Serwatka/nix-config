{ config, pkgs, ... }:

{
  # Import hardware config for this host
  imports = [
    ./hardware-configuration.nix
    ../modules/syncthing.nix  # Custom system-level module
  ];

  # Host-specific system settings
  networking.hostName = "desktop";
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable and parameterize Syncthing service (via your module)
  mySyncthing = {
    enable = true;
    guiUser = "admin";
    guiPassword = "6beRmEkbhRDevQrFAmz*";
    guiAddress = "127.0.0.1:8384";
  };

  # Required for system upgrades, rollbacks, etc.
  system.stateVersion = "25.05";
}
