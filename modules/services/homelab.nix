# Workstation access to core. The travelling laptop uses the tailnet for both
# SSH and private HTTPS names; the desktop keeps its independent LAN route.
{
  config,
  lib,
  ...
}: let
  coreLan = "192.168.0.125";
  # From tailscale status. Recheck if core is removed and rejoined to the tailnet.
  coreTailnet = "100.109.198.88";
  coreAddress =
    if config.myConfig.homelab.useTailnet
    then coreTailnet
    else coreLan;
in {
  options.myConfig.homelab.useTailnet = lib.mkEnableOption "access core over Tailscale while travelling";

  config = {
    # Both workstations are interactive machines, so there is no authKeyFile
    # here (unlike hosts/kiosk-common.nix, which has to join unattended). Join
    # once by hand:
    #   sudo tailscale up --accept-dns=false
    #
    # --accept-dns=false deliberately: the tailnet has no MagicDNS or
    # nameservers to offer, and with an exit node selected "use Tailscale DNS"
    # sends every lookup to the exit node's peer API, which core's firewall
    # does not answer. The one name that needs pinning is `core` itself (below);
    # every service name resolves through public DNS (core's tailnet IP) or
    # the router (its LAN IP).
    services.tailscale.enable = true;

    # No private CAs are trusted any more. pi-server's and core's Caddy
    # internal CAs only ever signed `tls internal` names, and the last of those
    # (dash/status.home.arpa) were retired on core on 2026-10-05. Every name
    # core serves now has a public Let's Encrypt certificate.
    networking.hosts.${coreAddress} = ["core"];

    # System defaults leave each user's existing Git hosts and SSH identities
    # intact. `core` follows the host's networking.hosts entry above; the two
    # explicit aliases pick a route regardless of which host they run on.
    #
    # core-lan matters on the laptop, where `core` is a tailnet address: with
    # tailscaled down, or at a venue with no internet, the bare name resolves
    # to an unroutable 100.x and hangs rather than failing. On the LAN,
    # core-lan is the way back in. HostKeyAlias keeps all three on core's
    # single known_hosts entry.
    programs.ssh.extraConfig = ''
      Host core core-lan core-remote
        User ${config.myConfig.primaryUser}
        ServerAliveInterval 30
        ServerAliveCountMax 3

      Host core-lan
        HostName ${coreLan}
        HostKeyAlias core

      Host core-remote
        HostName ${coreTailnet}
        HostKeyAlias core
    '';
  };
}
