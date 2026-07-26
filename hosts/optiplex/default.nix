# hosts/optiplex/default.nix — Dell OptiPlex game kiosk
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/graphics.nix
    # Intel thermal throttling daemon — this box runs a game around the clock.
    ../../modules/services/thermald.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix);
  # gameName is just the log label — keep it in sync with whatever's deployed.
  myConfig.kiosk.gameName = "Veilkeeper";

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
