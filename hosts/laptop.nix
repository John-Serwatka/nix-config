# hosts/laptop.nix — laptop-specific system config
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
        ../modules/services/asusd.nix
        ../modules/services/thermald.nix
        ../modules/services/printing.nix

        # Graphics
        ../modules/hardware/amdgpu.nix

        # Input devices
        ../modules/hardware/bluetooth.nix
        ../modules/hardware/network-adapter.nix

        # Output devices
        ../modules/services/audio-pipewire.nix

        # Low-level hardware scan (from your generated config)
        ./laptop-hardware.nix
  ];

  networking.hostName = "laptop";

    # ensure the system user exists
    users.users.withrin = {
        isNormalUser = true;
        extraGroups  = [ "wheel" "networkmanager" "input" ];
  };

  services.asusd.enable = true;
  services.asusd.setPerformanceProfile = true;

  services.bluetooth = true;
  services.bluetooth.enableGui = true;

  networking.enableManager    = true;
  networking.openTCPPorts     = [ 25565 ];

  services.thermald = true;

  services.printing = true;

  system.stateVersion = "25.05";

  # Syncthing overrides
  syncthing.enable      = true;
  syncthing.user        = "withrin";
  syncthing.dataDir     = "/home/withrin/.config/syncthing";
  syncthing.guiUser     = "admin";
  syncthing.guiPassword = "6beRmEkbhRDevQrFAmz*";
  syncthing.guiAddress  = "127.0.0.1:8384";

  # add laptop-only options (touchpad, battery, etc.) here
}
