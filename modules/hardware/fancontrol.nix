{ config, lib, ... }:

{
  options.services.fancontrol.enable = lib.mkEnableOption ''
    Enable lm-sensors and fancontrol (requires running `sensors-detect` once).
  '';

  config = lib.mkIf config.services.fancontrol.enable {
    hardware.sensors.enable             = true;
    services.hardware.fancontrol.enable = true;
  };
}
