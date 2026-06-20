{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.rclone;
in {
  options.my.rclone = {
    enable = lib.mkEnableOption "rclone mounts";

    mounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          remote = lib.mkOption {
            type = lib.types.str;
            example = "PocketLore_gdrive:";
            description = "The rclone remote name, including the trailing colon.";
          };

          mountPoint = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/cloud/${name}";
            description = "Where to mount the remote.";
          };

          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--vfs-cache-mode=full"
              "--dir-cache-time=12h"
              "--poll-interval=5m"
              "--umask=022"
              "--config=${config.home.homeDirectory}/.config/rclone/rclone.conf"
            ];
            description = "Extra arguments passed to rclone mount.";
          };
        };
      }));
      default = {};
      description = "Named rclone mounts.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rclone];

    systemd.user.services =
      lib.mapAttrs'
      (
        name: mountCfg:
          lib.nameValuePair "rclone-mount-${name}" {
            Unit = {
              Description = "rclone mount: ${name}";
              After = ["network-online.target"];
              Wants = ["network-online.target"];
            };

            Service = {
              Type = "simple";
              ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountCfg.mountPoint}";
              ExecStart = lib.concatStringsSep " " ([
                  "${pkgs.rclone}/bin/rclone"
                  "mount"
                  mountCfg.remote
                  mountCfg.mountPoint
                  "--daemon-timeout=30s"
                ]
                ++ mountCfg.extraArgs);
              ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u ${mountCfg.mountPoint}";
              Restart = "on-failure";
              RestartSec = "10";
            };

            Install.WantedBy = ["default.target"];
          }
      )
      cfg.mounts;
  };
}
