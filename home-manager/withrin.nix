# home-manager/withrin.nix
{ config, pkgs, ... }: {

  # Pin the Home-Manager state version here:
  home.stateVersion = "24.05";

  # Pull in your shared home config (which may also define programs, packages, etc.)
  imports = [ ../home.nix ];
}
