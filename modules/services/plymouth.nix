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
{pkgs, ...}: let
  logo = ../../assets/branding/pocketlore-logo.png;

  # Stock `spinner` with two changes, both learned the hard way on the beelink:
  #
  #   * The logo is scaled. plymouth does NOT scale images, and the source art
  #     is 2834x2657 — against a 32x32 throbber. Dropped in raw it is ~2.6x the
  #     height of a 1080p panel, so almost all of it lands off-screen and the
  #     boot looks simply black.
  #   * The watermark is centred. Stock spinner pins it at .96, i.e. hard against
  #     the bottom edge, which is right for a small distro badge and wrong for
  #     the only thing on the screen.
  #
  # Derived from the packaged theme rather than written from scratch so the
  # throbber frames and the two-step module config stay whatever plymouth ships.
  pocketloreTheme = pkgs.runCommand "plymouth-theme-pocketlore" {} ''
    dir=$out/share/plymouth/themes/pocketlore
    mkdir -p "$dir"
    cp -r ${pkgs.plymouth}/share/plymouth/themes/spinner/. "$dir/"
    mv "$dir/spinner.plymouth" "$dir/pocketlore.plymouth"

    ${pkgs.imagemagick}/bin/magick ${logo} -resize 600x600 "$dir/watermark.png"

    # ImageDir must point at this theme; the initrd builder rewrites store paths
    # under /share/plymouth/themes, and this path matches that pattern.
    sed -i \
      -e "s,^ImageDir=.*,ImageDir=$dir," \
      -e "s,^WatermarkVerticalAlignment=.*,WatermarkVerticalAlignment=.5," \
      -e "s,^Name=.*,Name=Pocket Lore," \
      "$dir/pocketlore.plymouth"
  '';
in {
  boot.plymouth = {
    enable = true;

    # Not the NixOS default `bgrt`: that deliberately reuses the *firmware's*
    # ACPI BGRT image, which would put the vendor's badge on a booth machine
    # instead of ours.
    theme = "pocketlore";
    themePackages = [pocketloreTheme];

    # Also written to /etc/plymouth/logo.png, which some tooling reads. Must
    # live inside the flake tree — the real branding directory is outside this
    # repo and Nix cannot read from there.
    inherit logo;
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
