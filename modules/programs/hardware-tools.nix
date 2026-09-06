# modules/programs/hardware-tools.nix — system/hardware admin tools
#
# User-facing utilities (udiskie, flameshot, nextcloud-client) live in the per-user
# profile profiles/home/utilities.nix. rclone is provided per-user by the Home
# Manager rclone service (modules/home/rclone.nix) when my.rclone.enable.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    usbutils # lsusb
    lm_sensors # hardware temperature monitoring
    # udisks is not listed: services.udisks2 (enabled by Plasma) installs it,
    # and pkgs.udisks is the same derivation as pkgs.udisks2.
  ];
}
