# modules/core/bootloader.nix — systemd-boot, latest kernel, EFI
# GPU-specific kernel params (e.g. nvidia blacklist) live in their hardware modules.
{pkgs, ...}: {
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # The boot-menu entry editor lets anyone with a keyboard append
  # `init=/bin/sh` and boot to a root shell, bypassing SDDM and every password
  # on the box. That is unacceptable on a kiosk sitting at a public booth, and
  # nothing here needs it, so it is off everywhere rather than kiosk-scoped.
  boot.loader.systemd-boot.editor = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
