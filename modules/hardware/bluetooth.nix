# modules/hardware/bluetooth.nix — Bluetooth hardware + Blueman tray
{ ... }:

{
  hardware.bluetooth.enable = true;
  services.blueman.enable   = true;
}
