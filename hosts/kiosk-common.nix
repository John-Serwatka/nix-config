# hosts/kiosk-common.nix — shared base for the game-kiosk machines
#
# Default boot = kiosk mode (modules/services/kiosk.nix): autologin straight
# into the host's game. The `work` specialisation in the systemd-boot menu
# (default 5s timeout) gives the regular Plasma desktop for game deploys and
# basic working; `withrin` is the login there.
{lib, ...}: {
  imports = [
    # Core
    ../modules/core/nix.nix
    ../modules/core/locale.nix
    ../modules/core/bootloader.nix
    ../modules/core/sops.nix

    # Programs
    ../modules/programs/cli.nix

    # Services
    ../modules/services/audio.nix
    ../modules/services/kiosk.nix

    # Hardware
    ../modules/hardware/network.nix
  ];

  myConfig.kiosk.enable = true;

  networking.enableManager = true;

  # WiFi/GPU firmware blobs (the Beelink has wireless; harmless on the OptiPlex).
  hardware.enableRedistributableFirmware = true;

  # Boot-menu alternative: full desktop, listed automatically by systemd-boot.
  # The default entry stays kiosk mode.
  specialisation.work.configuration = {
    imports = [
      ../modules/services/desktop.nix # Plasma 6 + SDDM
      ../modules/programs/browsers.nix
      ../modules/programs/utilities.nix
    ];
    # Drop the greetd/kiosk session so SDDM is the display manager here.
    myConfig.kiosk.enable = lib.mkForce false;
  };
}
