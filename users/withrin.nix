# users/withrin.nix — system user + Home Manager entry
{ config, pkgs, ... }:

{
  # recreate your user on each host
  users.users.withrin = {
    isNormalUser = true;
    description  = "John Serwatka";
    extraGroups  = [ "networkmanager" "wheel" "input" ];
  };

  # pull in all of your shared Home Manager config
  home-manager.users.withrin = import ../home.nix;
}
