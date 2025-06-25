# modules/services/asusd.nix
{ config, pkgs, lib, ... }:

with pkgs;

{
  # Option Declarations
  options.services.asusd.enable = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "Enable the ASUS Control Daemon (asusd).";
  };

  options.services.asusd.setPerformanceProfile = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "At login, set the ASUS profile to 'performance' via a user service.";
  };

  # Module Config #
  config = lib.recursiveUpdate
    (lib.mkIf config.services.asusd.enable {
      systemd.services.asusd = {
        description   = "ASUS Control Daemon";
        wantedBy      = [ "multi-user.target" ];
        after         = [ "network.target" ];
        serviceConfig = {
          Type      = "simple";
          ExecStart = "${asusctl}/bin/asusd";
        };
      };
    })
    (lib.mkIf config.services.asusd.setPerformanceProfile {
      systemd.user.services.set-asus-profile = {
        description   = "Set ASUS profile to performance at login";
        wantedBy      = [ "default.target" ];
        after         = [ "default.target" ];
        serviceConfig = {
          Type      = "oneshot";
          ExecStart = "${asusctl}/bin/asusctl profile set performance";
        };
      };
    });
}
