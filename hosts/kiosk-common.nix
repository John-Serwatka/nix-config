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

  # Fallback runtime for vendor builds whose Linux export is broken — Horde of
  # Viscount's ships on a 2016-era GameMaker runner that crashes on controller
  # enumeration, while its Windows build runs clean. Costs ~0.6 GiB and nothing
  # uses it unless a deployed build's run.sh calls `wine`.
  myConfig.kiosk.enableWine = true;

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
    # Laptop (~/.ssh/id_ed25519) so it can SSH in and drive `just deploy` /
    # `just kiosk-deploy` against the kiosks, over the tailnet or the LAN.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1Dul40V/Z3WrED3DXnZY9TDhIWMu0HQz/7n/fsH/0u withrin@laptop"
  ];

  # Two ways in, and a kiosk keeps whichever it can get:
  #
  #   * On the home tailnet — reachable from anywhere the box has internet, as
  #     `beelink`/`optiplex` over MagicDNS. This is how you reach one that lives
  #     at a venue.
  #   * On the LAN — port 22 is already open on the physical interface (openssh
  #     defaults openFirewall = true), so a box on an offline venue network with
  #     no tailnet is still reachable from a laptop on the same switch/AP.
  #
  # Both are always live; neither depends on the other being up. tailscale0 is a
  # trusted interface so SSH — and therefore `just deploy` and `just
  # kiosk-deploy`, which are both SSH — work over the tailnet with no extra
  # ports opened. The daemon opens its own UDP port for direct connections.
  #
  # Headless join: authKeyFile points at a reusable auth key in SOPS, so a
  # freshly installed kiosk joins the tailnet on first boot with no console. The
  # key is only consulted while the box is unauthenticated — once joined, state
  # persists in /var/lib/tailscale and the key is never read again, so an expired
  # or rotated key never knocks an already-joined box off the tailnet.
  #
  # Minting the real key (one-time; replaces the placeholder in secrets.yaml):
  #   * Tailscale admin console → Settings → Keys → Generate auth key
  #   * Reusable + Pre-approved, non-ephemeral (survives reboots). Tag it (e.g.
  #     tag:kiosk) if you gate device approval by ACL.
  #   * SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  #       nix run nixpkgs#sops -- secrets/secrets.yaml   # set tailscale_authkey
  # Until then the box still boots and LAN SSH still works; only the auto-join is
  # inert (the placeholder key just fails to authenticate).
  services.tailscale.enable = true;
  services.tailscale.authKeyFile = config.sops.secrets.tailscale_authkey.path;
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # Consumed by tailscale above. Declared here rather than in the shared
  # core/sops.nix so it is kiosk-scoped — desktop/laptop never decrypt a key
  # they don't use. Present in secrets.yaml (placeholder until a real key is
  # set), so sops-install-secrets finds it and activation doesn't fail.
  sops.secrets.tailscale_authkey = {};

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
