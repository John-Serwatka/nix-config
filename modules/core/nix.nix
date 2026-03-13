# modules/core/nix.nix — Nix daemon settings, flake support, unfree packages
{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
}
