# modules/services/syncthing.nix — Syncthing file sync + system tray
#
# Set `myConfig.syncthingUser` in the host to configure which user runs Syncthing.
# Example:  myConfig.syncthingUser = "withrin";
{ config, lib, pkgs, ... }:

with lib;

{
  options.myConfig.syncthingUser = mkOption {
    type        = types.str;
    description = "Username to run Syncthing for (sets dataDir and configDir).";
  };

  config = {
    services.syncthing = {
      enable           = true;
      user             = config.myConfig.syncthingUser;
      dataDir          = "/home/${config.myConfig.syncthingUser}/Sync";
      configDir        = "/home/${config.myConfig.syncthingUser}/.config/syncthing";
      openDefaultPorts = true;
    };

    #systemd.user.services.syncthingtray = {
    #  description = "Syncthing tray indicator";
    #  after       = [ "default.target" "syncthing.service" ];
    #  wantedBy    = [ "default.target" ];
    #  serviceConfig = {
    #    Type      = "simple";
    #    ExecStart = "${pkgs.syncthingtray}/bin/syncthingtray --wait";
    #  };
    #};
  };
}
