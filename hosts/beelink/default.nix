# hosts/beelink/default.nix — Beelink SER game kiosk (Horde of Viscount)
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
  ];

  myConfig.kiosk.gameName = "Horde of Viscount";

  myConfig.graphics.vendor = "amd";

  networking.hostName = "beelink";

  system.stateVersion = "26.05";
}
