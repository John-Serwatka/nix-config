# modules/disk/kiosk.nix — declarative disk layout for the game kiosks
#
# Importing this makes disko own the host's filesystems, so its hardware.nix
# carries only kernel modules and microcode — no per-machine UUIDs. That is the
# point: a kiosk can be reinstalled onto replacement hardware without anyone
# hand-editing a generated file (see the README).
#
# Only hosts that are provisioned this way should import it. The desktop and
# laptop were installed once and keep their generated hardware.nix; disko earns
# nothing there.
#
# Provision a machine with:
#
#   disko-install --flake /etc/nix-config#beelink --disk main /dev/nvme0n1
#
# `--disk main <device>` overrides myConfig.diskDevice below, so the value here
# only needs to be right for a plain `nixos-rebuild`.
{
  config,
  lib,
  ...
}:
with lib; {
  options.myConfig.diskDevice = mkOption {
    type = types.str;
    example = "/dev/nvme0n1";
    description = ''
      Whole-disk device disko partitions for this host. Deliberately has no
      default — an unset value fails evaluation rather than silently
      partitioning whatever happens to be /dev/sda.

      Confirm with `lsblk` on the target before installing. Prefer a stable
      /dev/disk/by-id/... path on machines with more than one drive.
    '';
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.myConfig.diskDevice;
    content = {
      type = "gpt";
      partitions = {
        # Explicit priority so the ESP is always partition 1; disko sorts
        # equal-priority partitions non-deterministically.
        ESP = {
          priority = 100;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # Keeps the ESP root-only; kernels and initrds live here.
            mountOptions = ["umask=0077"];
          };
        };

        # A game that overcommits should swap rather than get OOM-killed
        # mid-session on a show floor.
        swap = {
          size = "8G";
          content.type = "swap";
        };

        # size = "100%" gives this priority 9001 in disko, so it is created
        # last and absorbs the remaining space regardless of attribute order.
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
