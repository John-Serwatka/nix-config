# hosts/optiplex/default.nix — Dell OptiPlex game kiosk (Veilkeeper)
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/intel-graphics.nix
    # Intel thermal throttling daemon — this box runs a game around the clock.
    ../../modules/services/thermald.nix
  ];

  myConfig.kiosk.gameName = "Veilkeeper";

  # Intel iGPU (media/VA-API stack comes from intel-graphics.nix).
  services.xserver.videoDrivers = ["modesetting"];

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
