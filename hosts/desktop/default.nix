# hosts/desktop/default.nix — desktop machine configuration
{...}: {
  imports = [
    ./hardware.nix

    # Core
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/bootloader.nix
    ../../modules/core/sops.nix

    # Programs
    ../../modules/programs/cli.nix
    ../../modules/programs/browsers.nix
    ../../modules/programs/hardware-tools.nix
    ../../modules/programs/steam.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/avahi.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/ollama.nix
    ../../modules/services/syncthing.nix
    ../../modules/services/networking.nix

    # Hardware
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
    ../../modules/hardware/openrgb.nix
    ../../modules/hardware/desktop-input.nix
    ../../modules/hardware/bluetooth.nix
  ];

  # Skip access-time metadata writes on the SSDs (merges into the mount
  # options from hardware.nix).
  fileSystems."/".options = ["noatime"];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/b9d2c837-c3ab-4297-9b12-30e3c0279519";
    fsType = "ext4";
    options = ["defaults" "nofail" "noatime"];
  };

  # Compressed RAM swap, tried before the 8G swapfile (higher priority) —
  # OOM headroom for heavy builds without hitting the SSD.
  zramSwap.enable = true;

  # Configured users are added to the docker group automatically (modules/core/users.nix).
  virtualisation.docker.enable = true;

  # Trust the self-hosted Caddy private CAs (certs live in ../../certs).
  #
  # Two of them, because there are two Caddy instances and each runs its own
  # internal CA — they are unrelated roots, not a shared one:
  #
  #   caddy-ca.crt       pi-server's, "Caddy Local Authority - 2025 ECC Root".
  #                      Serves vault.home.com and drive.johnserwatka.com.
  #   core-caddy-ca.crt  core's, "Caddy Local Authority - 2026 ECC Root".
  #                      Serves dash.home.arpa and status.home.arpa, and
  #                      budget.johnserwatka.com until it gets a real
  #                      certificate at cutover.
  #
  # Without core's root here, its hosts resolve fine but every request is a
  # certificate error — trusting the Pi's CA does nothing for core.
  #
  # Re-extract if core is ever reinstalled (the CA is regenerated with it):
  #   ssh withrin@core 'curl -s localhost:2019/pki/ca/local' \
  #     | jq -r .root_certificate > certs/core-caddy-ca.crt
  security.pki.certificates = [
    (builtins.readFile ../../certs/caddy-ca.crt)
    (builtins.readFile ../../certs/core-caddy-ca.crt)
  ];

  myConfig.graphics.vendor = "nvidia";

  networking.hostName = "desktop";
  myConfig.networking.enableManager = true;
  myConfig.networking.openTCPPorts = [25565];

  # Tailscale, so this machine can reach the kiosks by MagicDNS name instead of
  # whatever address DHCP handed them. `just deploy <host>` and `just
  # kiosk-deploy <dir> <game> <host>` both use the host argument as an SSH name,
  # so without this they only work against raw IPs — which move.
  #
  # No authKeyFile here, unlike hosts/kiosk-common.nix: this is an interactive
  # workstation, not a headless appliance that has to join unattended. Join it
  # once by hand, the same way the laptop was:
  #   sudo tailscale up --accept-dns=false
  #
  # --accept-dns=false deliberately: this machine sits on the same LAN as
  # pi-server, and letting tailscale take over resolution would route DNS away
  # from it. The cost is no MagicDNS, which networking.hosts below replaces.
  services.tailscale.enable = true;

  # Kiosks by name without MagicDNS. Tailscale addresses are stable for the life
  # of a node — unlike the DHCP leases these boxes get, which move between
  # sessions — so pinning them here is what makes `just deploy optiplex` and
  # `just kiosk-deploy <dir> <game> optiplex` work at all. Covers rsync, ping and
  # anything else too, which an ssh config alone would not.
  #
  # Re-derive an entry if a box is ever removed from and re-added to the tailnet;
  # it gets a new address. Check with `tailscale status`.
  #
  # REMOTE ONLY. These are tailnet addresses, so they need internet — at a venue
  # with none, the tailnet is unavailable and `ssh optiplex` resolves to an
  # unroutable 100.x address and *hangs* rather than failing. On site use the
  # mDNS names instead, which need nothing but the local switch:
  #   ssh optiplex.local
  networking.hosts = {
    "100.91.165.90" = ["optiplex"];
    "100.108.113.115" = ["optiplex2"];

    # The `beelink` pin (100.108.89.104) is gone: that box was reinstalled as
    # the homelab server `core` and left the kiosk fleet, so the tailnet node it
    # named no longer exists. Its replacement is below.

    # The homelab server. A LAN address, not a tailnet one, unlike the kiosks
    # above — this machine sits on the same subnet as the desktop and holds a
    # DHCP reservation, so the LAN path always works and does not depend on the
    # tailnet being reachable.
    #
    # dash/status.home.arpa are Caddy virtual hosts on core (see the homelab
    # repo, modules/services/caddy.nix). They resolve nowhere else — `home.arpa`
    # is RFC 8375's reserved domain for home networks and has no public DNS — so
    # without this entry the browser simply fails to resolve them.
    #
    # Not listed here: budget.johnserwatka.com. That name has a public A record
    # still pointing at pi-server (192.168.0.250), which is deliberate — the Pi
    # serves it until the sub-project 4 cutover, which is a DNS record change
    # rather than anything on this machine.
    "192.168.0.125" = ["core" "dash.home.arpa" "status.home.arpa"];
  };

  system.stateVersion = "25.05";
}
