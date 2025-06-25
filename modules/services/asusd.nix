# modules/services/asusd.nix
{ config, pkgs, lib, ... }:

{
  options.services.asusd.setPerformanceProfile = lib.mkOption {
    type        = lib.types.bool;
    default     = false;
    description = "At login, set ASUS profile to 'performance'.";
  };

  config = lib.mkIf config.services.asusd.setPerformanceProfile {
    systemd.user.services.set-asus-profile = {
      description   = "Set ASUS performance profile";
      wantedBy      = [ "default.target" ];
      serviceConfig = {
        Type      = "oneshot";
        ExecStart = "${pkgs.asusctl}/bin/asusctl profile set performance";
      };
    };
  };
}
