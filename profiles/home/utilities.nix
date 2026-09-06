# profiles/home/utilities.nix — user-facing desktop utilities (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/utilities.nix ];
#
# System/hardware admin tools (usbutils, lm_sensors) stay host-side in
# modules/programs/hardware-tools.nix.
{pkgs, ...}: {
  # udiskie is not here: Plasma already enables services.udisks2 and ships the
  # device notifier, so a second automount daemon on top of the same backend
  # was one owner too many. Every host importing this profile runs Plasma.

  # Managed as a user service so the tray daemon actually starts with the
  # graphical session. The module installs the package itself, so flameshot is
  # deliberately absent from home.packages below.
  services.flameshot.enable = true;

  # The household Drive. Syncs a local folder against Nextcloud on `core`
  # (https://drive.johnserwatka.com) — this is the "folder you work out of"
  # that the whole homelab migration existed to provide.
  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  home.packages = with pkgs; [
    # Unlike the flameshot module, services.nextcloud-client only references
    # the store path from its ExecStart — it never adds the package to the
    # profile, so the launcher and menu entry need this line.
    nextcloud-client
  ];
}
