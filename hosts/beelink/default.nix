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

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix)
  # and the launcher labels its logs from the deployed directory, so nothing here
  # names a game.

  # This box will run the same monitors as the OptiPlex, where 120 Hz is
  # verified working; without this it takes the EDID-preferred 60 Hz and smears.
  # See hosts/optiplex/default.nix for why 120 rather than 144 or 240.
  myConfig.kiosk.refreshHz = 120;

  myConfig.graphics.vendor = "amd";

  networking.hostName = "beelink";

  # Trialling the hidden boot menu on this box before moving the OptiPlexes to
  # it (kiosk-common defaults to 1). Overriding here rather than there so a
  # failed key-hold test only affects one machine.
  #
  # Safe to try because losing the menu does not lose the box: SSH over ethernet
  # reaches root, and `systemctl reboot --boot-loader-menu=N` forces the menu on
  # the next boot regardless of the timeout. Revert to 1 if space-hold turns out
  # not to be catchable on this firmware.
  boot.loader.timeout = 0;

  system.stateVersion = "26.05";
}
