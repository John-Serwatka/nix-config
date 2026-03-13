# modules/hardware/nvidia.nix — proprietary NVIDIA driver, kernel params, udev rules
{ config, pkgs, ... }:

{
  # Blacklist nouveau so the proprietary driver takes over
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    package                      = config.boot.kernelPackages.nvidiaPackages.stable;
    open                         = false;
    powerManagement.enable       = false;
    modesetting.enable           = true;
    nvidiaSettings               = true;
    forceFullCompositionPipeline = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Ensure /dev/nvidia* nodes are world-readable for GPU compute
  services.udev.extraRules = ''
    KERNEL=="nvidia*", MODE="0666"
  '';
}
