{ config, pkgs, lib, ... }:

{
  options.services.thermald = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "Enable thermald for CPU thermal management.";
  };

  config = lib.mkIf config.services.thermald {
    services.thermald.enable = true;
  };
}
