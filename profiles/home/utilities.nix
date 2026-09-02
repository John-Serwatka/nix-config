# profiles/home/utilities.nix — user-facing desktop utilities (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/utilities.nix ];
#
# System/hardware admin tools (usbutils, udisks, lm_sensors) stay host-side in
# modules/programs/hardware-tools.nix.
{pkgs, ...}: {
  home.packages = with pkgs; [
    udiskie # automount tray daemon
    flameshot # screenshot to clipboard
    # The household Drive. Syncs a local folder against Nextcloud on `core`
    # (https://drive.johnserwatka.com) — this is the "folder you work out of"
    # that the whole homelab migration existed to provide.
    nextcloud-client
  ];
}
