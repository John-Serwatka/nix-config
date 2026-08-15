# modules/services/avahi.nix — mDNS, so machines answer to <hostname>.local
#
# This is the name resolution that works at a venue. Tailscale/MagicDNS needs
# to reach controlplane.tailscale.com, so on an offline network the tailnet is
# unavailable and 100.x addresses are unroutable. mDNS needs nothing but the
# local switch: plug into any router, no internet, no DHCP reservations, no
# router configuration, and `optiplex.local` resolves.
#
# Both name paths coexist deliberately — they are different names:
#
#   optiplex          tailnet address (remote, needs internet)
#   optiplex.local    mDNS (on-site, works offline)
#
# The booth dashboard uses the .local form (users/booth-admin/home.nix) because
# it is an on-site tool and must not depend on the venue having working
# internet.
{...}: {
  services.avahi = {
    enable = true;

    # Resolve <name>.local for lookups made *by* this machine. nssmdns6 is
    # deliberately left off: on a network without working IPv6 — which a venue
    # LAN often is — it adds a failing AAAA lookup to every resolution.
    nssmdns4 = true;

    # Announce this machine so others can find it. Without publish.addresses a
    # host resolves other names but never answers to its own.
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };

    # mDNS is UDP 5353; without this the firewall drops the queries and the
    # machine is silently invisible.
    openFirewall = true;
  };
}
