# modules/services/kiosk.nix — arcade-style game kiosk session
#
# Boots straight into a game: greetd autologins a dedicated passwordless user
# whose session is a supervising launcher that runs the game fullscreen under
# gamescope and relaunches it whenever it exits or crashes.
#
# greetd spawns default_session through PAM (the NixOS module sets
# startSession = true), so the kiosk user gets a real logind session: systemd
# user instance, XDG_RUNTIME_DIR, PipeWire, and seat-based device access
# (uaccess) all work without extra device groups. Not setting initial_session
# keeps services.greetd.restart at its default `true`, so greetd itself is a
# backstop if the launcher ever dies; the launcher's own loop is the primary
# supervisor.
#
# Game builds are deployed out-of-band: copy them under /opt/kiosk (owned by
# myConfig.primaryUser, so rsync needs no sudo) with an executable entrypoint
# at `command`. Launcher logs: `journalctl -t kiosk`.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myConfig.kiosk;

  # With capSysNice, the gamescope binary exists ONLY at /run/wrappers/bin —
  # the gamescope module deliberately keeps it out of systemPackages then.
  gamescopeBin =
    if config.programs.gamescope.capSysNice
    then "/run/wrappers/bin/gamescope"
    else getExe config.programs.gamescope.package;

  kioskRun = pkgs.writeShellScript "kiosk-run" ''
    # Tag everything for `journalctl -t kiosk`.
    exec &> >(${pkgs.systemd}/bin/systemd-cat -t kiosk)

    game=${escapeShellArg cfg.command}
    while true; do
      if [[ ! -x "$game" ]]; then
        echo "game launcher missing or not executable: $game — retrying in 10s"
        sleep 10
        continue
      fi
      echo ${escapeShellArg "starting ${cfg.gameName}"}
      ${gamescopeBin} ${escapeShellArgs cfg.gamescopeArgs} -- "$game"
      status=$?
      echo ${escapeShellArg "${cfg.gameName} exited with status"} "$status — relaunching in 2s"
      sleep 2
    done
  '';
in {
  options.myConfig.kiosk = {
    enable = mkEnableOption "arcade-style game kiosk session";

    gameName = mkOption {
      type = types.str;
      default = "the game";
      description = "Display name of the game, used in launcher log lines.";
    };

    command = mkOption {
      type = types.str;
      default = "/opt/kiosk/game/run.sh";
      description = "Executable entrypoint of the game build (native Linux).";
    };

    gamescopeArgs = mkOption {
      type = types.listOf types.str;
      default = ["-f"];
      example = ["-f" "--adaptive-sync"];
      description = "Arguments passed to gamescope ahead of the game command.";
    };

    user = mkOption {
      type = types.str;
      default = "kiosk";
      description = "Dedicated account the kiosk session runs as.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      # Persistent writable home for saves/settings/shader caches
      # (e.g. Godot user:// data).
      home = "/var/lib/kiosk";
      createHome = true;
      # No password login — greetd autologin only. No wheel, no Home Manager
      # (deliberately kept out of mkHost's `users` list).
      hashedPassword = "!";
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${kioskRun}";
        user = cfg.user;
      };
    };

    programs.gamescope = {
      enable = true;
      # Lets gamescope renice itself. mkDefault so a host can turn it off if
      # the capability wrapper misbehaves on its hardware (gamescopeBin above
      # follows automatically).
      capSysNice = mkDefault true;
    };

    # Controller udev rules (uaccess) without installing Steam.
    hardware.steam-hardware.enable = true;

    # Deploy target for game builds; primary user can rsync without sudo.
    systemd.tmpfiles.rules = [
      "d /opt/kiosk 0755 ${config.myConfig.primaryUser} users - -"
    ];
  };
}
