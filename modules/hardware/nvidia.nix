# modules/hardware/nvidia.nix — enable NVIDIA drivers
{ config, pkgs, ... }:

{
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    nvidiaSettings     = true;
    # you can override `package` if you need a specific version:
    # package = pkgs.linuxPackages.nvidia_x11;
  };
}
