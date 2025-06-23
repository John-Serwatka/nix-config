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

    # Graphics
    ../modules/hardware/nvidia.nix
    ../modules/hardware/vulkan.nix

    # Input devices
    ../modules/hardware/desktop-input.nix

    # Output devices
    ../modules/services/audio-pipewire.nix

    # Low-level hardware scan (from your generated config)
    ../hardware/desktop-hardware.nix
  ];

  networking.hostName = "desktop";

  # Syncthing overrides
  syncthing.enable      = true;
  syncthing.user        = "withrin";
  syncthing.dataDir     = "/home/withrin/.config/syncthing";
  syncthing.guiUser     = "admin";
  syncthing.guiPassword = "6beRmEkbhRDevQrFAmz*";
  syncthing.guiAddress  = "127.0.0.1:8384";
}
