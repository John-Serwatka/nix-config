# hosts/optiplex/default.nix — Dell OptiPlex game kiosk
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/graphics.nix
    # Intel thermal throttling daemon — this box runs a game around the clock.
    ../../modules/services/thermald.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix)
  # and the launcher labels its logs from the deployed directory, so nothing here
  # names a game.

  # High-refresh panels commonly advertise 60 Hz as their EDID-preferred mode,
  # and gamescope takes it — which smears on VA. 120 Hz needs a 297 MHz pixel
  # clock, inside HDMI 1.4's 340 MHz limit; 144 Hz (346 MHz) and 240 Hz
  # (594 MHz) need HDMI 2.0 and fall back *silently* if the link cannot carry
  # them, so 120 is the value that holds across panels and cables.
  #
  # Confirmed at 120 Hz on both panels tried here: Samsung LC27RG50 and the
  # Acer QG241Y G currently attached. Monitors get swapped between these boxes,
  # so verify rather than assume:
  #   journalctl -t kiosk -b | grep "selecting mode"
  myConfig.kiosk.refreshHz = 120;

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
