# Repair Plasma pins that otherwise break when an old Nix generation is GC'd.
{
  config,
  lib,
  pkgs,
  ...
}: let
  repair = pkgs.writeShellApplication {
    name = "plasma-fix-launchers";
    runtimeInputs = [pkgs.kdePackages.qttools pkgs.coreutils];
    text = ''
      dry_run=false
      case "''${1:-}" in
        --dry-run) dry_run=true ;;
        "") ;;
        *) echo "Usage: plasma-fix-launchers [--dry-run]" >&2; exit 2 ;;
      esac

      script=$(cat ${./plasma-launchers.js})
      changes=$(qdbus org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript "var applyChanges = false; $script")

      if [[ "$dry_run" == true ]]; then
        printf '%s\n' "$changes"
        exit 0
      fi
      [[ "$changes" != '[]' ]] || exit 0

      # Back up only when a repair is needed. Use Plasma's API for the write:
      # editing appletsrc behind a running shell can be overwritten on logout.
      backup_dir=${lib.escapeShellArg "${config.xdg.stateHome}/plasma-launchers"}
      mkdir -p "$backup_dir"
      backup=$(mktemp "$backup_dir/repair-XXXXXXXX.json")
      printf '%s\n' "$changes" > "$backup"
      qdbus org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript "var applyChanges = true; $script"
    '';
  };
in {
  home.packages = [repair];

  # Run once at login and again whenever Plasma saves panel changes. The
  # script writes only changed launchers, so the file watch settles after a
  # repair. No fixed panel IDs or hardcoded list of the user's pinned apps.
  systemd.user.services.plasma-fix-launchers = {
    Unit = {
      Description = "Keep Plasma launchers independent of Nix generations";
      After = ["plasma-plasmashell.service"];
      Requisite = ["plasma-plasmashell.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe repair;
    };
    Install.WantedBy = ["plasma-workspace.target"];
  };

  systemd.user.paths.plasma-fix-launchers = {
    Unit = {
      Description = "Watch Plasma for generation-specific launcher paths";
      PartOf = ["graphical-session.target"];
    };
    Path.PathChanged = "${config.xdg.configHome}/plasma-org.kde.plasma.desktop-appletsrc";
    Install.WantedBy = ["plasma-workspace.target"];
  };
}
