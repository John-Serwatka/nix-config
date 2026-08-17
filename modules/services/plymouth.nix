# modules/services/plymouth.nix — graphical boot splash, so a booth machine
# shows the studio logo instead of scrolling kernel and systemd output.
#
# Kiosk-scoped by import (hosts/kiosk-common.nix) rather than global: on the
# desktop and laptop that log is diagnostic and worth keeping on screen.
#
# What this can and cannot cover, measured on the beelink: Plymouth starts with
# the kernel, so it hides the ~13s of initrd + userspace text. The ~14s of
# firmware POST and bootloader ahead of that belong to the vendor and are not
# reachable from here — the boot is quiet, not branded end to end.
{...}: {
  boot.plymouth = {
    enable = true;

    # `spinner` renders boot.plymouth.logo centred. The NixOS default is `bgrt`,
    # which deliberately reuses the *firmware's* ACPI BGRT image — that would
    # put the vendor's badge on a booth machine instead of ours.
    theme = "spinner";

    # Must live inside the flake tree; the real branding directory is outside
    # this repo and Nix cannot read from there.
    logo = ../../assets/branding/pocketlore-logo.png;
  };

  # Plymouth draws the splash, but the kernel and udev keep writing to the
  # console underneath and that text tears straight through it. These are what
  # actually make the boot quiet — without them the logo flickers over scrolling
  # log lines, which looks worse than leaving the log alone.
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  # No `loglevel=` here on purpose: boot.consoleLogLevel above already emits
  # one, and the kernel takes the last occurrence — a second would silently win
  # or lose depending on ordering. `splash` is added by the plymouth module.
  boot.kernelParams = [
    "quiet"
    "udev.log_priority=3"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=false"
  ];
}
