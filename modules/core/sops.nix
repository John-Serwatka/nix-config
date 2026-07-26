# modules/core/sops.nix — encrypted secrets via sops-nix
#
# The sops-nix NixOS module is wired in globally by lib/mkHost.nix. Recipients
# live in ./.sops.yaml; encrypted material lives under ./secrets (safe to commit).
#
# ── Decryption key ────────────────────────────────────────────────────────────
# Two mechanisms, picked automatically by whether the host runs sshd:
#
# * Hosts WITH sshd (the kiosks) decrypt with an age identity derived from
#   /etc/ssh/ssh_host_ed25519_key. sops-nix does this by default via
#   `sops.age.sshKeyPaths`, and nothing has to be placed by hand: install the
#   box, read its derived key with
#       ssh withrin@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
#   add it to .sops.yaml, `sops updatekeys secrets/secrets.yaml`, and deploy.
#   The host key is generated at install time and persists, so there is no
#   separate secret to copy around, lose, or back up.
#
# * Hosts WITHOUT sshd (desktop, laptop) have no host key — sops-nix's
#   defaultImportKeys returns [] when services.openssh.enable is false — so
#   they keep a manual age key OUTSIDE the repo at
#     /home/<primaryUser>/.config/sops/age/keys.txt   (mode 600)
#   generated once with `age-keygen`. Back that file up; losing it means those
#   secrets can't be decrypted. That key is also what you use to *edit*
#   secrets, so it stays a recipient regardless.
#
# Setting age.keyFile unconditionally is what made the first kiosk install
# painful: sops-install-secrets treats a configured-but-missing keyFile as a
# fatal error, so a fresh box failed activation until the file was placed by
# hand — which needed a login, whose password came from the secret it could not
# yet decrypt.
#
# ── Adding a secret ───────────────────────────────────────────────────────────
# 1. Edit the encrypted store:  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
#       nix run nixpkgs#sops -- secrets/secrets.yaml
# 2. Declare it in `sops.secrets` below.
# 3. Consume it via the *file-based* option of whatever you configure, using
#    `config.sops.secrets.<name>.path` — never interpolate a secret's value into
#    a Nix string (that would land world-readable in the Nix store). E.g.
#       users.users.<u>.hashedPasswordFile = config.sops.secrets.<u>_password.path;
#       networking.wireless.secretsFile     = config.sops.secrets.wifi.path;
#
# Note: the Syncthing module has no file-based GUI-password option, so keep that
# password out of the repo and set it in the Syncthing web UI.
#
# ── Deliberately NOT managed here (yet) — TODO: circle back ────────────────────
# rclone.conf: the gdrive remote uses an OAuth token that rclone rewrites when it
# refreshes, so a read-only sops secret would break token rotation. Left imperative
# for now (~/.config/rclone/rclone.conf, see modules/home/rclone.nix). Revisit
# deliberately as one of:
#   * a service account (static creds) if it fits the Drive use case, or
#   * a writable runtime config generated from an encrypted seed, or
#   * a manual per-machine rclone config kept outside the repo.
# Until then, keep sops focused on stable secrets (password hashes, API tokens, …).
{
  config,
  lib,
  ...
}: {
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    # Only where there is no host key to derive from; see the header. Left
    # unset (null) on sshd hosts so age.sshKeyPaths takes over.
    age.keyFile =
      lib.mkIf (!config.services.openssh.enable)
      "/home/${config.myConfig.primaryUser}/.config/sops/age/keys.txt";

    secrets = {
      # User login password hash. neededForUsers makes it available early enough
      # for account creation (decrypted to /run/secrets-for-users/<name>).
      withrin_password = {
        neededForUsers = true;
      };
    };
  };
}
