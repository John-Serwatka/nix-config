# modules/programs/utilities.nix — system utilities and hardware tools
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    usbutils # lsusb
    udiskie # automount
    udisks # disk management
    lm_sensors # hardware temperature monitoring
    rclone # remote syncing
    flameshot # screenshot to clipboard
    seafile-client # seafile desktop client for self hosted drive on pi
  ];
}
