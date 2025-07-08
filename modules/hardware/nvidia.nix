{ config, pkgs, ... }:

{
  # Enable the OpenGL stack so that X (and apps) pick up the NVIDIA driver
  hardware.opengl.enable = true;

  hardware.nvidia = {
    package          = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    powerManagement.enable = false;
    modesetting.enable = true;
    nvidiaSettings     = true;
    forceFullCompositionPipeline = true;
  };

  # X server + SDDM on X11 (fallback from Wayland for stability)
  services.xserver = {
    enable = true;
    displayManager = {
        sddm = {
            enable  = true;
            wayland = { enable = false; };
        };
    };
    videoDrivers = [ "nvidia" ];
  };

  # Extra udev rule so that /dev/nvidia* nodes are created with 0666 permissions
  services.udev.extraRules = ''
    KERNEL=="nvidia*", MODE="0666"
  '';
}
