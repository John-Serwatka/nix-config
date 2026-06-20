# modules/core/sops.nix — encrypted secrets via sops-nix
#
# The sops-nix NixOS module is wired in globally by lib/mkHost.nix, so secrets
# are available on every host. This file is where you turn it on and declare
# what to decrypt. It is intentionally INERT until you do the one-time setup
# below — with no `sops.secrets` defined, nothing is read and the build stays
# green even before any key or secrets file exists.
#
# ── One-time setup ────────────────────────────────────────────────────────────
# 1. Generate an age key for this machine (kept OUTSIDE the repo):
#       mkdir -p ~/.config/sops/age
#       nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
#    Copy the printed public key (age1...) into ./.sops.yaml.
#
#    (Alternatively, derive an age key from the host's SSH key so you don't have
#    to distribute a separate file — see the sops-nix README.)
#
# 2. Create and edit the encrypted secrets file:
#       nix run nixpkgs#sops -- secrets/secrets.yaml
#    Add entries such as:
#       syncthing_gui_password: "rotate-me-to-a-fresh-value"
#       wifi_home_psk:          "..."
#
# 3. Uncomment the `sops` block below and declare each secret you want decrypted,
#    then `nixos-rebuild switch`.
#
# ── How to consume a secret ───────────────────────────────────────────────────
# A declared secret is decrypted to a file at /run/secrets/<name>; reference it
# with `config.sops.secrets.<name>.path`. Use the *file-based* option of whatever
# you're configuring — never interpolate the secret's value into a Nix string,
# or it would land world-readable in the Nix store. Examples:
#       users.users.withrin.hashedPasswordFile = config.sops.secrets.user_pw.path;
#       networking.wireless.secretsFile         = config.sops.secrets.wifi.path;
#
# Note on Syncthing: the NixOS Syncthing module has no file-based GUI-password
# option, so it can't pull the password from sops cleanly. Keep the Syncthing
# GUI password OUT of this repo entirely and set it in the Syncthing web UI
# instead (which is the current arrangement).
{...}: {
  # sops = {
  #   defaultSopsFile = ../../secrets/secrets.yaml;
  #   age.keyFile     = "/home/withrin/.config/sops/age/keys.txt";
  #
  #   secrets = {
  #     # wifi_home_psk = { };
  #   };
  # };
}
