# modules/services/thermald.nix
{ config, pkgs, ... }:

{
  services.thermald.enable = true;
}
