# hosts/optiplex/default.nix — Dell OptiPlex game kiosk (Veilkeeper)
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/graphics.nix
    # Intel thermal throttling daemon — this box runs a game around the clock.
    ../../modules/services/thermald.nix
  ];

  myConfig.kiosk = {
    gameName = "Veilkeeper";
    command = "/opt/kiosk/veilkeeper/run.sh";
  };

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
