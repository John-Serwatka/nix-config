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

  # Reach the kiosks as the restricted booth-control account over the tailnet
  # (MagicDNS names) with LAN fallback. These blocks must NEVER fall back to an
  # interactive prompt — a missing key or wrong perms has to fail fast instead of
  # hanging the TUI — hence BatchMode + every password path disabled + short,
  # bounded timeouts. Identity is the dedicated booth-control key (generated
  # one-time, see the repo plan / kiosk-common.nix TODO).
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
      optiplex = common // {HostName = "optiplex";};
      beelink = common // {HostName = "beelink";};
    };
  };
}
