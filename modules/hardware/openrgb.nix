{ config, lib, ... }:

{
  options.services.openrgb.enable = lib.mkEnableOption "OpenRGB daemon";

  config = lib.mkIf config.services.openrgb.enable {
    hardware.openrgb.enable = true;   # adds system-wide udev rules & service
  };
}
