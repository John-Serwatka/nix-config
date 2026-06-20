# modules/hardware/vulkan.nix — Vulkan/OpenGL loaders and tooling
{pkgs, ...}: {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Runtime loaders for the graphics stack.
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    # vulkan-validation-layers   # uncomment for Vulkan debugging
  ];

  # CLI tooling (vulkaninfo, vkcube, …).
  environment.systemPackages = with pkgs; [
    vulkan-tools
  ];
}
