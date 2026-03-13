# modules/core/bootloader.nix — systemd-boot, latest kernel, EFI
# GPU-specific kernel params (e.g. nvidia blacklist) live in their hardware modules.
{ pkgs, ... }:

{
  boot.loader.grub.enable              = false;
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages                  = pkgs.linuxPackages_latest;
}
