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

  # The attached Samsung LC27RG50 is a 240 Hz VA panel, but its EDID-preferred
  # mode is 60 Hz — which gamescope was picking, and VA panels smear badly at
  # 60 Hz. 120 Hz needs a 297 MHz pixel clock, inside HDMI 1.4's 340 MHz limit;
  # 144 Hz (346 MHz) and 240 Hz (594 MHz) both require HDMI 2.0, so they may
  # silently fall back depending on this box's port. Verify with
  # `journalctl -t kiosk -b | grep "selecting mode"`.
  myConfig.kiosk.refreshHz = 120;

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
