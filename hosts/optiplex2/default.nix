# hosts/optiplex2/default.nix — second Dell OptiPlex game kiosk (3070)
#
# Unlike ../optiplex, this box was provisioned with disko from the start, so it
# has no hardware.nix at all: disko owns the filesystems, the initrd modules a
# generated file would list are NixOS defaults, and the per-vendor bits (Intel
# microcode, usb_storage) live in ../optiplex-common.nix. Nothing here is
# specific to this physical machine except which disk to partition.
{...}: {
  imports = [
    ../optiplex-common.nix
    ../../modules/disk/kiosk.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix)
  # and the launcher labels its logs from the deployed directory, so nothing here
  # names a game.

  # Confirmed with `lsblk` on the box: a 119.2 GB SanDisk SD7SB3Q SATA SSD, the
  # only non-removable disk present. Only affects partitioning — disko mounts by
  # /dev/disk/by-partlabel/, so this value does not participate in booting.
  myConfig.diskDevice = "/dev/sda";

  networking.hostName = "optiplex2";

  # First installed on 26.11 — deliberately not optiplex's 26.05.
  system.stateVersion = "26.11";
}
