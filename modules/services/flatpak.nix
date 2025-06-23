# modules/services/flatpak.nix
{ config, ... }:

{
  services.flatpak.enable = true;
  services.xdg.portal.enable = true;
}
