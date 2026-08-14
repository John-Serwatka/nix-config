# hosts/optiplex/default.nix — Dell OptiPlex game kiosk
#
# Shared OptiPlex settings (Intel graphics, thermald, 120 Hz, platform modules)
# live in ../optiplex-common.nix. This host is still on its generated
# hardware.nix rather than disko — see that file for why the disko import is not
# shared yet.
{...}: {
  imports = [
    ./hardware.nix
    ../optiplex-common.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix)
  # and the launcher labels its logs from the deployed directory, so nothing here
  # names a game.

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
