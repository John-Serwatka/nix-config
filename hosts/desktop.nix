{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
#    (import ../modules/syncthing.nix {
#      inherit config pkgs lib;
#      syncthingUser = "withrin";
#      syncthingDataDir = "/home/withrin/.config/syncthing";
#    })
  ];


  networking.hostName = "desktop";

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    nvidiaSettings = true;
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

#  mySyncthing = {
#    enable = true;
#    guiUser = "admin";
#    guiPassword = "6beRmEkbhRDevQrFAmz*";
#    guiAddress = "127.0.0.1:8384";
#  };

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [
      "modprobe.blacklist=nouveau"
      "nouveau.modeset=0"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
#  boot.loader.systemd-boot.enable = true;
#  boot.loader.grub.enable = false;
#  boot.loader.grub.efiSupport = true;
#  boot.loader.grub.efiInstallAsRemovable = true;
#  boot.loader.grub.devices = [ "/dev/sda" ]; # Adjust as needed

  # Just list the extra packages you need—NixOS will merge them for you
#  environment.systemPackages = [
#    config.hardware.nvidia.package
#    config.hardware.nvidia.package.bin
 #   ];

  system.stateVersion = "25.05";
}
