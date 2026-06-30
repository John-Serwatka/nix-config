# profiles/home/utilities.nix — user-facing desktop utilities (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/utilities.nix ];
#
# System/hardware admin tools (usbutils, udisks, lm_sensors) stay host-side in
# modules/programs/utilities.nix.
{pkgs, ...}: {
  home.packages = with pkgs; [
    udiskie # automount tray daemon
    flameshot # screenshot to clipboard
    seafile-client # Seafile desktop client (self-hosted drive on pi)
  ];
}
