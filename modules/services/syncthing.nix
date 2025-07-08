# modules/services/syncthing.nix (deprecated wrapper)
{ config
, lib
, syncthingUser ? "withrin"
, syncthingDataDir ? "/home/withrin/.config/syncthing"
, ...
}:

{
  ########################################
  ##  Deprecation notice  ###############
  ########################################

  _module.deprecatedReason = ''
    This custom Syncthing wrapper is obsolete.
    Switch to the built-in `services.syncthing` options
    (see <https://search.nixos.org/options?channel=unstable&show=services.syncthing>).
  '';

  ########################################
  ##  Compatibility options (unchanged) ##
  ########################################
  options.syncthing = {
    enable  = lib.mkEnableOption "DEPRECATED";
    user    = lib.mkOption { type = lib.types.str; default = syncthingUser; };
    dataDir = lib.mkOption { type = lib.types.str; default = syncthingDataDir; };
    guiUser     = lib.mkOption { type = lib.types.str; default = "admin";     };
    guiPassword = lib.mkOption { type = lib.types.str; default = "changeme";  };
    guiAddress  = lib.mkOption { type = lib.types.str; default = "127.0.0.1:8384"; };
  };

  ########################################
  ##  Forward settings + extra warning  ##
  ########################################
  config = lib.mkIf config.syncthing.enable {
    warning = "⚠️  `syncthing.*` is deprecated; replace with `services.syncthing.*`";

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
