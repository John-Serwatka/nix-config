# modules/hardware/bluetooth.nix — Bluetooth hardware + Blueman tray
{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        AutoEnable = true;
        Experimental = false;
        FastConnectable = true;
      };
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="bluetooth", KERNEL=="hci0", ATTR{power/control}="on"
  '';
}
