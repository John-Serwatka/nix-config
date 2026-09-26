# hosts/desktop/game-broker.nix — the desktop's side of the game-stream broker
#
# core (the homelab box) may wake this machine and, later, ask it to start a
# Steam session for Moonlight. It only ever *asks*: its key is pinned to a
# dispatcher with fixed verbs, and every decision is made here from local
# state. Design and staging: docs/superpowers/plans/2026-09-25-game-streaming-broker.md.
#
# Stage 3 (this file today): sshd, and a read-only `status` verb.
{pkgs, ...}: let
  sshKeys = import ../../lib/ssh-keys.nix;

  # core's broker key. The private half is `desktop_broker_ssh_key` in the
  # homelab repo's sops file; it was generated in /dev/shm and exists nowhere
  # else.
  coreBrokerKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHAM8fqxyLSjp06VPlDJg2XeQ/XaJ1J75LfItf9KHRNn game-broker@core";

  # core's LAN and tailnet addresses. Tailnet devices using core's subnet
  # route also arrive as 192.168.0.125 (it SNATs), so this narrows where the
  # key works rather than proving it is core; the key is the real check.
  coreAddresses = "192.168.0.125,100.109.198.88";

  # A separate file so writeShellApplication shellchecks it as a whole script.
  # runtimeInputs come first on PATH; the rest is sshd's own, not the client's
  # (`restrict` and the default PermitUserEnvironment=no leave it no say).
  remote = pkgs.writeShellApplication {
    name = "game-broker-remote";
    runtimeInputs = with pkgs; [coreutils jq procps systemd];
    text = builtins.readFile ./game-broker/remote.sh;
  };
in {
  # LAN and tailnet only, like Sunshine's ports in ./default.nix (these lists
  # merge with those) — in particular not the kiosk USB share. So the module
  # must not add 22 to the global list.
  networking.firewall.interfaces.enp42s0.allowedTCPPorts = [22];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];

  # Kill withrin's processes when a session ends, so a logout actually ends.
  # With the NixOS default (false), pam_kwallet5's ksecretd outlived a COSMIC
  # logout and held the session in `closing` indefinitely — which `status`
  # rightly reports as `local`, so the broker could never start. It also kept
  # user@1000 alive, and with it a Sunshine that had restarted at the greeter.
  # withrin only: tmux/nohup under a withrin login (e.g. laptop SSH) now dies
  # with it — use `systemd-run --user` for anything that must outlive one.
  # logind does not restart on switch here; takes effect after a reboot.
  services.logind.settings.Login = {
    KillUserProcesses = true;
    KillOnlyUsers = "withrin";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["broker-control" "withrin"];
    };
  };

  # The laptop only: it is the recovery path into this machine (a normal shell,
  # sudo with a password) that does not depend on core. core never gets a
  # withrin key — its access is the restricted broker account below.
  users.users.withrin.openssh.authorizedKeys.keys = [sshKeys.laptop];

  # core's account. Unprivileged and not withrin, so the key can never become a
  # shell: restrict = no PTY, forwarding, agent, X11 or user rc; command= runs
  # the dispatcher whatever core asks for; from= limits where it may connect.
  # No sudo rule in Stage 3 — `status` needs none (logind and /proc are
  # readable by anyone).
  users.groups.broker-control = {};
  users.users.broker-control = {
    isSystemUser = true;
    group = "broker-control";
    home = "/var/lib/broker-control";
    createHome = true; # sshd runs the forced command via the login shell
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      ''restrict,command="${remote}/bin/game-broker-remote",from="${coreAddresses}" ${coreBrokerKey}''
    ];
  };
}
