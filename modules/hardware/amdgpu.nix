{ config, pkgs, ... }:

{
  hardware.opengl.enable       = true;
  hardware.opengl.driSupport32Bit = true;

  services.xserver.videoDrivers = [ "amdgpu" ];
}
