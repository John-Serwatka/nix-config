# hosts/desktop.nix — desktop-specific system config
{ config, pkgs, ... }:

{
  imports = [

    # Core settings & shared apps
    ../modules/shared.nix
    ../modules/bootloader.nix
    ../modules/apps/base.nix

    # Gaming stack
    ../modules/apps/games.nix

    # Services
    ../modules/services/flatpak.nix
    ../modules/services/steam.nix
    ../modules/services/syncthing.nix
    ../modules/services/xserver-plasma.nix

    # Graphics
    ../modules/hardware/nvidia.nix
    ../modules/hardware/vulkan.nix

    # Input devices
    ../modules/hardware/desktop-input.nix
    ../modules/hardware/network-adapter.nix

    # Output devices
    ../modules/services/audio-pipewire.nix

    # Low-level hardware scan (from your generated config)
    ./desktop-hardware.nix
  ];

  networking.hostName = "desktop";

hardware.bluetooth.enable = true;
services.blueman.enable  = true;

networking.networkmanager.enable = true;
networking.enableManager    = true;
networking.openTCPPorts     = [ 25565 ];

  # ensure the system user exists
  users.users.withrin = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "input" ];
  };

  system.stateVersion = "25.05";

  # Syncthing overrides
  syncthing.enable      = true;
  syncthing.user        = "withrin";
  syncthing.dataDir     = "/home/withrin/.config/syncthing";
  syncthing.guiUser     = "admin";
  syncthing.guiPassword = "6beRmEkbhRDevQrFAmz*";
  syncthing.guiAddress  = "127.0.0.1:8384";
}
