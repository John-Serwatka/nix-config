{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (import ../modules/syncthing.nix {
      inherit config pkgs lib;
      syncthingUser = "withrin";
      syncthingDataDir = "/home/withrin/.config/syncthing";
    })
  ];


  networking.hostName = "desktop";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.nvidia.open = false;
  hardware.opengl.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  mySyncthing = {
    enable = true;
    guiUser = "admin";
    guiPassword = "6beRmEkbhRDevQrFAmz*";
    guiAddress = "127.0.0.1:8384";
  };

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ]; # Adjust as needed


  system.stateVersion = "25.05";
}
