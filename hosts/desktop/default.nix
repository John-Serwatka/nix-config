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
    ../../modules/programs/obs.nix
    ../../modules/programs/hardware-tools.nix
    ../../modules/programs/steam.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/avahi.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/ollama.nix
    ../../modules/services/networking.nix
    ../../modules/services/homelab.nix

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

  myConfig.graphics.vendor = "nvidia";

  networking.hostName = "desktop";
  myConfig.networking.enableManager = true;
  myConfig.networking.openTCPPorts = [25565];

  # The USB ethernet adapter that shares this machine's internet with the kiosk
  # bench. NetworkManager's `shared` mode (the `usb-ethernet-share` connection)
  # runs a dnsmasq on it handing out 10.42.0.0/24 leases, so the interface needs
  # DHCP (UDP 67) and DNS (53, both protocols) open — the default-deny firewall
  # otherwise drops the requests and the kiosks never get an address.
  #
  # Host-specific on purpose: this is one adapter on one machine, and the name is
  # its physical USB path. It lived in modules/services/networking.nix keyed off
  # enableManager, which meant every NetworkManager host — both kiosks and the
  # laptop — carried a firewall rule for an interface that does not exist there.
  #
  # The name changes if it is moved to a different USB port. Check with
  # `ip -o link` while it is plugged in.
  networking.firewall.interfaces."enp45s0f3u2u2c2" = {
    allowedUDPPorts = [53 67];
    allowedTCPPorts = [53];
  };

  # Tailscale itself is enabled in modules/services/homelab.nix, imported above,
  # along with the reason this machine joins with --accept-dns=false. It earns
  # its keep here too: it is what lets this machine reach the kiosks by address
  # instead of whatever DHCP handed them. `just deploy <host>` and `just
  # kiosk-deploy <dir> <game> <host>` both use the host argument as an SSH name,
  # so without it they only work against raw IPs — which move.

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

    # core and its private HTTPS names are shared with the laptop through
    # modules/services/homelab.nix.
  };

  system.stateVersion = "25.05";
}
