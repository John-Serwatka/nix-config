# modules/programs/utilities.nix — system utilities and hardware tools
#
# User-facing utilities (udiskie, flameshot, seafile-client) live in the per-user
# profile profiles/home/utilities.nix. rclone is provided per-user by the Home
# Manager rclone service (modules/services/rclone.nix) when my.rclone.enable.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    usbutils # lsusb
    udisks # disk management
    lm_sensors # hardware temperature monitoring
  ];
}
