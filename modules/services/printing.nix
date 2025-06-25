{ config, pkgs, lib, ... }:

{
  options.services.printing = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "Enable CUPS printing service.";
  };

  config = lib.mkIf config.services.printing {
    services.printing.enable = true;
  };
}
