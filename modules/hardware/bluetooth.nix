# modules/services/bluetooth.nix
{ config, pkgs, lib, ... }:

with pkgs;

{
  # Option Declarations #
  options.services.bluetooth = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Bluetooth hardware support and stack.";
  };

  options.services.bluetooth.enableGui = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the Blueman GUI tray app for Bluetooth.";
  };

  # Module Config #

  config = lib.mkIf config.services.bluetooth {
    # Turn on the kernel & low-level stack
    hardware.bluetooth.enable = true;
    # If they asked for a GUI, turn on Blueman
    services.blueman.enable = config.services.bluetooth.enableGui;
  };
}
