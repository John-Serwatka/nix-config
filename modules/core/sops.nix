# modules/core/sops.nix — encrypted secrets via sops-nix
#
# The sops-nix NixOS module is wired in globally by lib/mkHost.nix. Recipients
# live in ./.sops.yaml; encrypted material lives under ./secrets (safe to commit).
#
# ── Decryption key ────────────────────────────────────────────────────────────
# Each machine holds a private age key OUTSIDE the repo at
#   /home/<primaryUser>/.config/sops/age/keys.txt   (mode 600)
# generated once with `age-keygen`. Its PUBLIC key is a recipient in .sops.yaml.
# Back this file up — losing it means the secrets can't be decrypted. On a fresh
# install, place the key file before the first switch (the user password is
# decrypted from it during account creation).
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
{config, ...}: {
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/home/${config.myConfig.primaryUser}/.config/sops/age/keys.txt";

    secrets = {
      # User login password hash. neededForUsers makes it available early enough
      # for account creation (decrypted to /run/secrets-for-users/<name>).
      withrin_password = {
        neededForUsers = true;
      };
    };
  };
}
