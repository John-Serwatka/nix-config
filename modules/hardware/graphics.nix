# modules/hardware/graphics.nix — unified GPU stack
#
# One module owns the graphics story: base GL/Vulkan stack, vendor-specific
# drivers, and the X/Wayland driver list. Hosts pick their GPU with
#   myConfig.graphics.vendor = "amd" | "intel" | "nvidia";
#
# videoDrivers is set with mkDefault, so a host that needs a custom list
# (e.g. the laptop adds displaylink) can assign its own — a normal-priority
# assignment replaces the default rather than concatenating with it.
#
# Note: vulkan-loader is deliberately NOT in extraPackages — Mesa/NVIDIA
# provide the Vulkan ICDs, and applications bring their own loader.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myConfig.graphics;

  defaultVideoDrivers = {
    amd = ["amdgpu"];
    intel = ["modesetting"];
    nvidia = ["nvidia"];
  };
in {
  options.myConfig.graphics.vendor = mkOption {
    type = types.enum ["amd" "intel" "nvidia"];
    description = "GPU vendor of this host; selects the driver stack and default videoDrivers.";
  };

  config = mkMerge [
    {
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;

      # CLI tooling (vulkaninfo, vkcube, …).
      environment.systemPackages = with pkgs; [
        vulkan-tools
      ];

      services.xserver.videoDrivers = mkDefault defaultVideoDrivers.${cfg.vendor};
    }

    (mkIf (cfg.vendor == "intel") {
      # VA-API drivers: intel-media-driver (iHD) covers Broadwell and newer,
      # intel-vaapi-driver (i965) covers older generations.
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    })

    (mkIf (cfg.vendor == "nvidia") {
      # Blacklist nouveau so the proprietary driver takes over.
      boot.blacklistedKernelModules = ["nouveau"];
      boot.kernelParams = [
        "modprobe.blacklist=nouveau"
        "nouveau.modeset=0"
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
      ];

      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = false;
        powerManagement.enable = false;
        modesetting.enable = true;
        nvidiaSettings = true;
        forceFullCompositionPipeline = true;
      };

      # Ensure /dev/nvidia* nodes are world-readable for GPU compute.
      services.udev.extraRules = ''
        KERNEL=="nvidia*", MODE="0666"
      '';
    })
  ];
}
