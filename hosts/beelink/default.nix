# hosts/beelink/default.nix — Beelink SER game kiosk
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix);
  # gameName is just the log label — keep it in sync with whatever's deployed.
  myConfig.kiosk.gameName = "Veilkeeper";

  myConfig.graphics.vendor = "amd";

  networking.hostName = "beelink";

  system.stateVersion = "26.05";
}
