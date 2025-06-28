# modules/services/network-adapter.nix
{ config, lib, pkgs, ... }:

with lib;

{
  # Option Declarations
  options.networking.enableManager = mkOption {
    type        = types.bool;
    default     = false;
    description = "Enable NetworkManager (manages wired & wireless interfaces).";
  };

  options.networking.openTCPPorts = mkOption {
    type        = types.listOf types.int;
    default     = [];
    example     = [ 22 80 443 25565 ];
    description = "A list of TCP ports to allow through the firewall.";
  };

  # Module Config
  config = mkIf config.networking.enableManager {
      networking.networkmanager.enable = true;
    }
    // mkIf (config.networking.openTCPPorts != []) {
      networking.firewall.enable          = true;
      networking.firewall.allowedTCPPorts = config.networking.openTCPPorts;
    };
}
