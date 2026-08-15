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

  # Trust the self-hosted Caddy private CA (cert lives in ../../certs).
  security.pki.certificates = [
    (builtins.readFile ../../certs/caddy-ca.crt)
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
  # optiplex2 and beelink are absent because they have not joined yet — they
  # still need the deploy carrying the real auth key. Add them once
  # `tailscale status` shows them.
  networking.hosts = {
    "100.91.165.90" = ["optiplex"];
  };

  system.stateVersion = "25.05";
}
