# modules/services/printing.nix
{ config, lib, ... }:

{
  # Option Declaration  #
  options.services.printing.enable = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "Enable CUPS printing service.";
  };

  # Module Config #
  config = lib.mkIf config.services.printing.enable {
    services.printing.enable = true;
  };
}
