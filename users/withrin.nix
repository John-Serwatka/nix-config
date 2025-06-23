# users/withrin.nix — system user + Home Manager entry
{ config, pkgs, ... }:

{
  # pull in all of your shared Home Manager config
  home-manager.users.withrin = import ../home.nix;
}
