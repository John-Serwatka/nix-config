# hosts/beelink/hardware.nix — Beelink SER kernel/firmware detail
#
# No fileSystems or swapDevices here: disko owns them (modules/disk/kiosk.nix),
# which is why this file has no machine-specific UUIDs and survives a move to
# replacement hardware. Everything below is generic to the platform.
#
# If a future Beelink needs different initrd modules, regenerate with
# `nixos-generate-config --no-filesystems` and copy the boot.* lines only.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
