# hosts/beelink/hardware.nix — PLACEHOLDER hardware configuration
#
# ┌──────────────────────────────────────────────────────────────────────────┐
# │ TODO: replace this ENTIRE file with the output of `nixos-generate-config`│
# │ run on the actual Beelink SER. The values below only exist so the flake  │
# │ evaluates before the box is installed — they will NOT boot real hardware.│
# └──────────────────────────────────────────────────────────────────────────┘
{
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

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
