# users/withrin/default.nix — system-level user account definition
# To add a new user: copy this directory, adjust username and groups.
#
# Note: the "docker" group is added per-host (e.g. hosts/desktop/default.nix)
# only where virtualisation.docker is enabled — otherwise the group would not
# exist on hosts without Docker.
{...}: {
  users.users.withrin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "input"];
  };
}
