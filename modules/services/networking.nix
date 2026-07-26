# modules/services/networking.nix
{
  config,
  lib,
  ...
}:
with lib; {
  options.myConfig.networking.enableManager = mkOption {
    type = types.bool;
    default = false;
    description = "Enable NetworkManager (manages wired & wireless interfaces).";
  };

  options.myConfig.networking.openTCPPorts = mkOption {
    type = types.listOf types.port;
    default = [];
    example = [ 22 80 443 25565 ];
    description = "A list of TCP ports to allow through the firewall.";
  };

  config = mkMerge [
    (mkIf config.myConfig.networking.enableManager {
      networking.networkmanager.enable = true;

      # Allow NetworkManager's DHCP and DNS services for Ethernet sharing.
      networking.firewall.interfaces."enp45s0f3u2u2c2" = {
        allowedUDPPorts = [ 53 67 ];
        allowedTCPPorts = [ 53 ];
      };
    })

    # The firewall is enabled by default; this only opens the listed ports.
    (mkIf (config.myConfig.networking.openTCPPorts != []) {
      networking.firewall.allowedTCPPorts =
        config.myConfig.networking.openTCPPorts;
    })
  ];
}