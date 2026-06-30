# users/withrin/default.nix — system-level user account definition
# To add a new user: copy this directory, adjust username and groups, then add
# the name to the host's `users` list in flake.nix (see README).
#
# Note: the "docker" group is added centrally (modules/core/users.nix) for every
# configured user on hosts where virtualisation.docker is enabled — so it is not
# listed here (the group would not exist on hosts without Docker).
{config, ...}: {
  users.users.withrin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "input"];
    # Login password hash, decrypted from sops (see modules/core/sops.nix).
    hashedPasswordFile = config.sops.secrets.withrin_password.path;
  };
}
