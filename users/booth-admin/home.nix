# users/booth-admin/home.nix — Home Manager profile for the booth operator
#
# Must be named home.nix: the laptop uses the default homeProfile = "home", and
# that stem applies to every user on the host (lib/mkHost.nix genAttrs). Kept
# deliberately slim — this login exists only to run the kiosk dashboard.
{...}: {
  imports = [
    ../../profiles/home/shell.nix
    ./booth-dashboard.nix
  ];
  home.stateVersion = "25.05"; # match the laptop host

  # Reach the kiosks as the restricted booth-control account over mDNS — see the
  # note on the Host blocks below for why deliberately *not* over the tailnet.
  # These blocks must NEVER fall back to an interactive prompt — a missing key or
  # wrong perms has to fail fast instead of hanging the TUI — hence BatchMode +
  # every password path disabled + short, bounded timeouts. Identity is the
  # dedicated booth-control key, which is generated one-time on this machine and
  # is NOT yet active: the matching public key goes in `boothAdminPublicKey` at
  # the top of hosts/kiosk-common.nix, which is still null, so the kiosks
  # authorize nobody for booth-control and every host here reads "offline".
  #
  # Uses the current programs.ssh.settings interface (the older matchBlocks is a
  # deprecated alias in this Home Manager); bare attr names become `Host` blocks
  # and bool/int values render as yes/no and numbers. enableDefaultConfig = false
  # drops HM's legacy `Host *` defaults (also deprecated) — unneeded here.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = let
      common = {
        User = "booth-control";
        IdentityFile = "~/.ssh/id_ed25519_booth_control";
        IdentitiesOnly = true;
        BatchMode = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        NumberOfPasswordPrompts = 0;
        StrictHostKeyChecking = "accept-new";
        ConnectTimeout = 3;
        ConnectionAttempts = 1;
        ServerAliveInterval = 2;
        ServerAliveCountMax = 1;
      };
    in {
      # .local, not the bare name or the tailnet address. This dashboard is an
      # on-site tool and a venue may have no internet, which takes the tailnet
      # with it — MagicDNS would resolve to a 100.x address nothing can route
      # to, and BatchMode means the failure is silent: every kiosk simply reads
      # "offline". mDNS (modules/services/avahi.nix) needs only the local
      # switch, so these names resolve on whatever network the booth is handed.
      #
      # The Host aliases stay short so booth-dashboard.nix's HOSTS array and the
      # `ssh <host> <verb>` calls in it need no change.
      optiplex = common // {HostName = "optiplex.local";};
      optiplex2 = common // {HostName = "optiplex2.local";};
    };
  };
}
