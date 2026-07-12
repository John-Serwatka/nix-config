# hosts/optiplex/default.nix — Dell OptiPlex game kiosk (Veilkeeper)
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/intel-graphics.nix
  ];

  myConfig.kiosk.gameName = "Veilkeeper";

  # Intel iGPU (media/VA-API stack comes from intel-graphics.nix).
  services.xserver.videoDrivers = ["modesetting"];

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
