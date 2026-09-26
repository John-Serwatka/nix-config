# hosts/desktop/game-broker.nix — the desktop's side of the game-stream broker
#
# core (the homelab box) may wake this machine and, later, ask it to start a
# Steam session for Moonlight. It only ever *asks*: its key is pinned to a
# dispatcher with fixed verbs, and every decision is made here from local
# state. Design and staging: docs/superpowers/plans/2026-09-25-game-streaming-broker.md.
#
# Stage 3 (this file today): sshd, and a read-only `status` verb.
{...}: let
  sshKeys = import ../../lib/ssh-keys.nix;
in {
  # LAN and tailnet only, like Sunshine's ports in ./default.nix (these lists
  # merge with those) — in particular not the kiosk USB share. So the module
  # must not add 22 to the global list.
  networking.firewall.interfaces.enp42s0.allowedTCPPorts = [22];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["withrin"];
    };
  };

  # The laptop only: it is the recovery path into this machine (a normal shell,
  # sudo with a password) that does not depend on core. core never gets a
  # withrin key — its access is the restricted broker account.
  users.users.withrin.openssh.authorizedKeys.keys = [sshKeys.laptop];
}
