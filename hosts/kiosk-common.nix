# hosts/kiosk-common.nix — shared base for the game-kiosk machines
#
# Default boot = kiosk mode (modules/services/kiosk.nix): autologin straight
# into the host's game. The `work` specialisation in the systemd-boot menu
# (default 5s timeout) gives the regular Plasma desktop for game deploys and
# basic working; `withrin` is the login there.
{
  config,
  lib,
  ...
}: {
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
    ../modules/services/networking.nix
  ];

  myConfig.kiosk.enable = true;

  # Deploy target for game builds; primary user can rsync without sudo. Lives
  # here (not in kiosk.nix's mkIf cfg.enable) so it still exists when booted
  # straight into the `work` specialisation, which force-disables the kiosk.
  systemd.tmpfiles.rules = [
    "d /opt/kiosk 0755 ${config.myConfig.primaryUser} users - -"
  ];

  myConfig.networking.enableManager = true;

  # Remote game deploys: rsync-over-ssh into /opt/kiosk (see
  # modules/services/kiosk.nix). Key-only auth; the kiosk user itself has no
  # password and no authorized keys, so only withrin can get in.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users.withrin.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINx1ujbVZk2s/RRjVfqLOyNS4HfV1vTNLLivpFIqP0YI withrin@desktop"
  ];

  # Remote *config* deploys (`just deploy <host>`): nixos-rebuild builds on the
  # desktop and nix-copy-closure pushes the result here. Those paths are built
  # locally and therefore unsigned, and only a trusted user may add unsigned
  # paths to the store — without this the copy fails with "lacks a signature by
  # a trusted key". Root is trusted by default but cannot log in over SSH here
  # (no key, PermitRootLogin prohibit-password), so the deploy user needs it.
  #
  # This is effectively root on the box, but that account already has wheel and
  # is the only one with an authorized key, so it grants nothing new.
  nix.settings.trusted-users = [config.myConfig.primaryUser];

  # WiFi/GPU firmware blobs (the Beelink has wireless; harmless on the OptiPlex).
  hardware.enableRedistributableFirmware = true;

  # Boot-menu alternative: full desktop, listed automatically by systemd-boot.
  # The default entry stays kiosk mode.
  specialisation.work.configuration = {
    imports = [
      ../modules/services/desktop.nix # Plasma 6 + SDDM
      ../modules/programs/browsers.nix
      ../modules/programs/hardware-tools.nix
    ];
    # Drop the greetd/kiosk session so SDDM is the display manager here.
    myConfig.kiosk.enable = lib.mkForce false;
  };
}
