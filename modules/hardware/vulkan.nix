{ config, pkgs, ... }:

{
#  hardware.opengl = {
    # enable the generic OpenGL/Vulkan support
#    enable       = true;
#    driSupport   = true;
#    driSupport32Bit = true;


    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    # extra packages for Vulkan tooling and loaders
    hardware.graphics.extraPackages = with pkgs; [
      vulkan-loader
      vulkan-tools        # includes vulkaninfo, etc.
      vulkan-headers
      # if you want validation layers:
      # vulkan-validate-layers
    ];
}

