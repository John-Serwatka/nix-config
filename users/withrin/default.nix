# users/withrin/default.nix — system-level user account definition
# To add a new user: copy this directory, adjust username and groups.
{ ... }:

{
  users.users.withrin = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "input" "docker" ];
  };
}
