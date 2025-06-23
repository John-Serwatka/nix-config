# modules/services/syncthing.nix
{ config, lib, syncthingUser ? "withrin", syncthingDataDir ? "/home/withrin/.config/syncthing", ... }:

{
  options.syncthing = {
    enable = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Enable Syncthing service with my custom wrapper.";
    };
    user = lib.mkOption {
      type        = lib.types.str;
      default     = syncthingUser;
      description = "System user to run Syncthing as.";
    };
    dataDir = lib.mkOption {
      type        = lib.types.str;
      default     = syncthingDataDir;
      description = "Path to Syncthing data directory.";
    };
    guiUser = lib.mkOption {
      type        = lib.types.str;
      default     = "admin";
      description = "Syncthing GUI username.";
    };
    guiPassword = lib.mkOption {
      type        = lib.types.str;
      default     = "changeme";
      description = "Syncthing GUI password.";
    };
    guiAddress = lib.mkOption {
      type        = lib.types.str;
      default     = "127.0.0.1:8384";
      description = "Address the Syncthing GUI listens on.";
    };
  };

  config = lib.mkIf config.syncthing.enable {
    services.syncthing = {
      enable           = true;
      user             = config.syncthing.user;
      dataDir          = config.syncthing.dataDir;
      openDefaultPorts = true;
      settings.gui = {
        user     = config.syncthing.guiUser;
        password = config.syncthing.guiPassword;
        address  = config.syncthing.guiAddress;
      };
    };
  };
}
