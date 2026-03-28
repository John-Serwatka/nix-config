# modules/hardware/bluetooth.nix — Bluetooth hardware + Blueman tray
{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };

  # disable blueman for now
  services.blueman.enable = false;
}