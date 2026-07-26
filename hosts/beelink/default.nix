# hosts/beelink/default.nix — Beelink SER game kiosk
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/disk/kiosk.nix
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
  ];

  # disko owns this host's partitioning and filesystems (modules/disk/kiosk.nix),
  # so hardware.nix carries no fileSystems block. Confirm the device with
  # `lsblk` on the box before installing — `disko-install --disk main <dev>`
  # overrides this at install time.
  myConfig.diskDevice = "/dev/nvme0n1";

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix);
  # gameName is just the log label — keep it in sync with whatever's deployed.
  myConfig.kiosk.gameName = "Veilkeeper";

  myConfig.graphics.vendor = "amd";

  networking.hostName = "beelink";

  system.stateVersion = "26.05";
}
