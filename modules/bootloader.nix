# modules/bootloader.nix
{ config, lib, ... }:

{
  # Disable GRUB, enable systemd-boot
  boot.loader.grub.enable         = false;
  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;


  # Kernel parameters & blacklists
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # If you need EFI support flags, add them here
   boot.loader.efi.canTouchEfiVariables = true;
}
