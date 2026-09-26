# hosts/desktop/default.nix — desktop machine configuration
{...}: let
  # See the Sunshine firewall comment further down.
  sunshinePorts = {
    allowedTCPPorts = [47984 47989 48010];
    allowedUDPPorts = [47998 47999 48000 48002 48010];
  };
in {
  imports = [
    ./hardware.nix
    ./game-broker.nix

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
    ../../modules/services/cosmic.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/ollama.nix
    ../../modules/services/networking.nix
    ../../modules/services/kdeconnect.nix
    ../../modules/services/homelab.nix
    ../../modules/services/sunshine.nix

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

  # Sunshine's stream ports (modules/services/sunshine.nix), on the house LAN
  # and the tailnet only. From the module's offsets on base port 47989:
  # TCP -5/0/21 and UDP 9/10/11/13/21. TCP +1 (47990, the web UI) is left out
  # on purpose. Not the kiosk share: nothing there should stream from here.
  #
  # "LAN" is looser than it looks: core is a Tailscale subnet router for
  # 192.168.0.0/24 and SNATs routed traffic, so a tailnet device using that
  # route arrives on enp42s0 as 192.168.0.125. Sunshine's own pairing is the
  # real access control; this only keeps the ports off other segments.
  networking.firewall.interfaces.enp42s0 = sunshinePorts;
  networking.firewall.interfaces.tailscale0 = sunshinePorts;

  # Keep decrypting with the manual age key now that sshd is on. Without this,
  # modules/core/sops.nix drops age.keyFile (it keys off openssh.enable) and
  # sops-nix switches to the freshly generated SSH host key, which is not a
  # recipient in .sops.yaml — withrin_password stops decrypting and the next
  # activation leaves withrin with no password. Both host-key paths are emptied
  # so exactly one identity is in play.
  sops.age.keyFile = "/home/withrin/.config/sops/age/keys.txt";
  sops.age.sshKeyPaths = [];
  sops.gnupg.sshKeyPaths = [];

  # Wake-on-LAN (magic packet) on the onboard NIC, so core can power this
  # machine up for a stream. Emitted as a udev .link file, which applies under
  # NetworkManager too. Needs ErP Ready = Disabled and Resume By PCI-E =
  # Enabled in the BIOS, or the NIC has no standby power in S5.
  networking.interfaces.enp42s0.wakeOnLan.enable = true;

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
