# modules/hardware/intel-graphics.nix — Intel iGPU graphics stack
{pkgs, ...}: {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # VA-API drivers: intel-media-driver (iHD) covers Broadwell and newer,
  # intel-vaapi-driver (i965) covers older generations.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];

  # Note: like amdgpu.nix, this module intentionally does not set
  # services.xserver.videoDrivers — the driver list is declared once per host.
}
