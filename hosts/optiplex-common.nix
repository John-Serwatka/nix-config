# hosts/optiplex-common.nix — shared base for the Dell OptiPlex game kiosks
#
# Everything both OptiPlexes agree on. The per-host files carry only what really
# differs: hostname, stateVersion, and the disk to partition.
#
# Deliberately does NOT import ../modules/disk/kiosk.nix yet. `optiplex` still
# declares fileSystems in its generated hardware.nix and disko declares them
# too, so importing it here would be an evaluation conflict until that host is
# migrated. Move the import up once both hosts are disko-managed.
{
  config,
  lib,
  ...
}: {
  imports = [
    ./kiosk-common.nix
    ../modules/hardware/graphics.nix
    # Intel thermal throttling daemon — these boxes run a game around the clock.
    ../modules/services/thermald.nix
  ];

  # High-refresh panels commonly advertise 60 Hz as their EDID-preferred mode,
  # and gamescope takes it — which smears on VA. 120 Hz needs a 297 MHz pixel
  # clock, inside HDMI 1.4's 340 MHz limit; 144 Hz (346 MHz) and 240 Hz
  # (594 MHz) need HDMI 2.0 and fall back *silently* if the link cannot carry
  # them, so 120 is the value that holds across panels and cables.
  #
  # Monitors get swapped between these boxes, so verify rather than assume:
  #   journalctl -t kiosk -b | grep "selecting mode"
  myConfig.kiosk.refreshHz = 120;

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";

  # ── Platform ────────────────────────────────────────────────────────────────
  # This is everything a generated hardware.nix would have carried, minus the
  # filesystems disko owns. All of it is per-vendor rather than per-machine,
  # which is why a disko-managed OptiPlex needs no generated file of its own.
  #
  # Not listed: ahci, nvme, sd_mod, usbhid, xhci_pci. All five are already in
  # boot.initrd.includeDefaultModules (default true) — verified by evaluating a
  # bare NixOS config against this flake's nixpkgs. usb_storage is the lone
  # exception, kept as cheap insurance so a box whose boot device appears behind
  # USB mass storage still finds its root instead of dropping to an initrd
  # prompt at a venue.
  boot.initrd.availableKernelModules = ["usb_storage"];

  # Intel microcode. enableRedistributableFirmware is already true from
  # kiosk-common.nix, but this option does not follow it automatically.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
