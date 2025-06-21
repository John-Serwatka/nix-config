{ config, pkgs, lib, syncthingUser ? "withrin", syncthingDataDir ? "/home/withrin/.config/syncthing", ... }:

{
  options.mySyncthing = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable my custom Syncthing module.";
    };
    guiUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Syncthing GUI username";
    };
    guiPassword = lib.mkOption {
      type = lib.types.str;
      default = "changeme";
      description = "Syncthing GUI password";
    };
    guiAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8384";
      description = "Syncthing GUI listen address";
    };
  };

  config = lib.mkIf config.mySyncthing.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = syncthingUser;
      dataDir = syncthingDataDir;
      settings.gui = {
        user = config.mySyncthing.guiUser;
        password = config.mySyncthing.guiPassword;
        address = config.mySyncthing.guiAddress;
      };
    };
  };
}
